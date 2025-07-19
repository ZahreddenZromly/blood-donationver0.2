// All repositories are included here
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory configurations
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Clean task for the project
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

// Buildscript block for classpath dependencies
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.0.4") // Make sure this version matches your setup
        classpath("com.google.gms:google-services:4.3.15") // Firebase services plugin
    }
}

