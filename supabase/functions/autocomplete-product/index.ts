// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'

console.log("Autocomplete Product Function Initialized")

Deno.serve(async (req) => {
    // Handle CORS Preflight request
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
            }
        })
    }

    try {
        const { brand, model } = await req.json()
        console.log(`Request received for: ${brand} - ${model}`)

        if (!model) {
            throw new Error('Model is required')
        }

        // 1. Setup Supabase Client with SERVICE ROLE for global logging/counting
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        const apiKey = Deno.env.get('GEMINI_API_KEY')

        if (!apiKey || !supabaseServiceKey) {
            console.error("Missing configuration: GEMINI_API_KEY or SUPABASE_SERVICE_ROLE_KEY")
            throw new Error('Server configuration error: Missing Secrets')
        }

        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        // 2. Define Model Strategy & Quotas (User Preference)
        const modelsPriority = [
            { name: 'gemini-3-flash-preview', rpm: 5, rpd: 20 },
            { name: 'gemini-2.5-flash', rpm: 5, rpd: 20 },
            { name: 'gemini-2.5-flash-lite', rpm: 10, rpd: 20 },
            { name: 'gemini-2.0-flash', rpm: 5, rpd: 20 },
            { name: 'gemini-2.0-flash-lite', rpm: 10, rpd: 20 },
            { name: 'gemini-1.5-flash', rpm: 15, rpd: 1500 }
        ]

        // 3. Fetch Available Models from API to validate existence
        let availableModelNames: string[] = []
        try {
            const modelsUrl = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`
            const modelsReq = await fetch(modelsUrl)
            if (modelsReq.ok) {
                const modelsData = await modelsReq.json()
                const list = modelsData.models || []
                // Normalize names: 'models/gemini-1.5-flash' -> 'gemini-1.5-flash'
                availableModelNames = list
                    .filter((m: any) => m.supportedGenerationMethods?.includes('generateContent'))
                    .map((m: any) => m.name.replace('models/', ''))

                console.log("Available Models (Subset):", availableModelNames.slice(0, 5))
            } else {
                console.warn("Model list fetch failed:", await modelsReq.text())
            }
        } catch (e) {
            console.warn("Failed to list models, using fallback list logic", e)
        }

        // 4. Select Best Available Model (Under Quota)
        let selectedModel = 'gemini-1.5-flash' // Default fallback
        let quotaHit = false

        // Check usage for prioritized models
        for (const candidate of modelsPriority) {
            // First check if it technically exists
            if (availableModelNames.length > 0) {
                // Fuzzy match name
                const exists = availableModelNames.some(n => n.includes(candidate.name))
                if (!exists) {
                    console.log(`Model ${candidate.name} not found in available list, skipping.`)
                    continue
                }
            }

            // Check Global RPM (Last Minute)
            const oneMinuteAgo = new Date(Date.now() - 60 * 1000).toISOString()
            const { count: rpmCount, error: rpmError } = await supabase
                .from('ai_request_logs')
                .select('*', { count: 'exact', head: true })
                .eq('model', candidate.name)
                .gte('created_at', oneMinuteAgo)

            if ((rpmCount || 0) >= candidate.rpm) {
                console.log(`Skipping ${candidate.name}: RPM Limit Reached (${rpmCount}/${candidate.rpm})`)
                continue
            }

            // Check Global RPD (Last 24 Hours)
            const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
            const { count: rpdCount, error: rpdError } = await supabase
                .from('ai_request_logs')
                .select('*', { count: 'exact', head: true })
                .eq('model', candidate.name)
                .gte('created_at', oneDayAgo)

            if ((rpdCount || 0) >= candidate.rpd) {
                console.log(`Skipping ${candidate.name}: RPD Limit Reached (${rpdCount}/${candidate.rpd})`)
                continue
            }

            // If we get here, this model is viable
            selectedModel = candidate.name
            break
        }

        console.log(`Selected Model for generation: ${selectedModel}`)


        // 5. Generate Content with Retries
        let apiResponse = null
        let errorDetail = null
        let status = 'success'

        // Try up to 3 models if we hit overload/quota issues
        const maxRetries = 3;
        let attempt = 0;
        let success = false;

        // Get list of candidates starting from selectedModel index
        const startIndex = modelsPriority.findIndex(m => m.name === selectedModel);
        // Create a fallback list: starting with selectedModel, then others not yet tried
        // For simplicity, let's just use the selectedModel and then fall back to others in priority order if they exist in availableModelNames

        // BETTER STRATEGY: 
        // We already picked 'selectedModel' based on quota. If it fails with 503, we should try a different one (maybe even one we skipped due to RPM if we are desperate? No, stick to quotas).
        // Let's just try the request. If 503, wait 1s and retry SAME model or NEXT available model?
        // 503 usually means "model overloaded". Switching model is a good idea.

        // Let's build a retry queue.
        const retryQueue = [selectedModel];
        // Add one or two fallbacks from the priority list that are VALID (in availableModelNames) and DIFFERENT from selectedModel
        for (const m of modelsPriority) {
            if (m.name !== selectedModel && availableModelNames.includes(m.name) && retryQueue.length < 3) {
                retryQueue.push(m.name);
            }
        }

        console.log("Retry Queue:", retryQueue);

        for (const modelToTry of retryQueue) {
            attempt++;
            const modelPath = modelToTry.startsWith('models/') ? modelToTry : `models/${modelToTry}`
            const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/${modelPath}:generateContent?key=${apiKey}`

            console.log(`Attempt ${attempt}: Trying ${modelToTry}...`);

            try {
                const response = await fetch(geminiUrl, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        contents: [{ parts: [{ text: prompt }] }]
                    })
                })

                if (!response.ok) {
                    const errText = await response.text();
                    const isOverloaded = response.status === 503 || response.status === 429;

                    if (isOverloaded) {
                        console.warn(`Model ${modelToTry} overloaded/rate-limited (${response.status}).`);
                        // If this was the last attempt, allow error to bubble up
                        if (attempt === retryQueue.length) {
                            status = response.status === 429 ? 'error_429' : 'error_other';
                            errorDetail = `API Error ${response.status}: ${errText}`;
                            throw new Error(errorDetail);
                        }
                        // Otherwise continue to next model
                        continue;
                    } else {
                        // Other errors (400, 401, etc) are fatal, do not retry
                        status = 'error_other';
                        errorDetail = `API Error ${response.status}: ${errText}`;
                        throw new Error(errorDetail);
                    }
                }

                apiResponse = await response.json();
                selectedModel = modelToTry; // Update selected model for logging
                success = true;
                break; // Success!

            } catch (e) {
                console.error(`Attempt ${attempt} failed:`, e);
                if (attempt === retryQueue.length) {
                    status = 'error_other'
                    errorDetail = e.message
                }
                // If not final attempt, loop continues
            }
        }

        if (!success && !errorDetail) {
            errorDetail = "All retry attempts failed.";
            status = 'error_other';
        }

        // 6. Log Usage
        await supabase.from('ai_request_logs').insert({
            model: selectedModel,
            status: status,
            details: errorDetail
        })

        if (errorDetail) {
            throw new Error(errorDetail)
        }

        const candidates = apiResponse?.candidates
        if (!candidates || candidates.length === 0) {
            // Safety block or refusal
            console.warn("No candidates returned. Safety/Refusal?", JSON.stringify(apiResponse))
            throw new Error("AI returned no results (Possible safety block or unknown model).")
        }

        const textResult = candidates[0]?.content?.parts?.[0]?.text
        console.log("Raw AI Response:", textResult)

        let cleanJson = textResult || "{}"
        cleanJson = cleanJson.replace(/```json/g, '').replace(/```/g, '').trim()

        let productData = {}
        try {
            productData = JSON.parse(cleanJson)
        } catch (e) {
            console.error("JSON Parse Error:", e, cleanJson)
            // Fallback if JSON is malformed
            // NOTE: User requested NO category in prompt, so we fallback with name/specs only
            productData = { name: `${brand} ${model}`, specs: cleanJson }
        }

        return new Response(
            JSON.stringify(productData),
            {
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                }
            },
        )

    } catch (error) {
        console.error("Function Error:", error)
        return new Response(
            JSON.stringify({ error: error.message }),
            {
                status: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                }
            },
        )
    }
})
