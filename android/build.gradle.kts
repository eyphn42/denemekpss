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
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Bu satır zaten vardır, versiyonu seninkiyle aynı kalsın (elleme)
        // Genelde şöyledir: classpath("com.android.tools.build:gradle:8.x.x")
        // Eğer hata verirse buraya dokunma, sadece alt satırı ekle.
        
        classpath("com.android.tools.build:gradle:8.2.1") // (Senin versiyon farklı olabilir, değiştirme)

        // --- İŞTE EKSİK OLAN VE EKLEMEN GEREKEN SATIR BU: ---
        classpath("com.google.gms:google-services:4.4.2")
    }
}