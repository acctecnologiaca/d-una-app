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


        // 5. Generate Content (User Prompt)
        const prompt = `
      Act as a product data expert. 
      I will provide a product Brand and Model. 
      You must return a JSON object with:
      1. "name": The full commercial name of the product in Headline Style format, but it can't include the brand name and the model.
      2. "specs": "A concise list (up to 300 characters) of technical specifications. Format each item on a new line, preceded by a hyphen and one space and ended by a period."
      
      If unknown, provide best guess based on model naming or return generic fields. 
      Everything has to be in Spanish. Just return JSON.

      Brand: ${brand || 'Unknown'}
      Model: ${model}
    `

        // Ensure URL format
        const modelPath = selectedModel.startsWith('models/') ? selectedModel : `models/${selectedModel}`
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/${modelPath}:generateContent?key=${apiKey}`

        let apiResponse = null
        let errorDetail = null
        let status = 'success'

        try {
            const response = await fetch(geminiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    contents: [{
                        parts: [{ text: prompt }]
                    }]
                })
            })

            if (!response.ok) {
                status = response.status === 429 ? 'error_429' : 'error_other'
                const err = await response.text()
                errorDetail = `API Error ${response.status}: ${err}`
                console.error("Gemini API Error details:", err)
                throw new Error(errorDetail)
            }

            apiResponse = await response.json()

        } catch (e) {
            status = 'error_other'
            errorDetail = e.message
            console.error("Fetch Exception:", e)
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
