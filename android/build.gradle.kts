allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    
    fun configureProject(p: Project) {
        val android = p.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        if (android != null && android.namespace == null) {
            android.namespace = "com.example.${p.name.replace("-", "_")}"
        }
        
        // Fix for whatsapp_share2 Manifest package attribute
        if (p.name == "whatsapp_share2") {
            val manifestFile = p.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                var content = manifestFile.readText()
                if (content.contains("package=\"com.example.whatsapp_share\"")) {
                    content = content.replace("package=\"com.example.whatsapp_share\"", "")
                    manifestFile.writeText(content)
                }
            }
        }
    }

    if (project.state.executed) {
        configureProject(project)
    } else {
        project.afterEvaluate {
            configureProject(this)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
