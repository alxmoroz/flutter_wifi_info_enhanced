# Исправление сборки wifi_info_enhanced для AGP 8.6.1

## Проблема

При использовании Android Gradle Plugin версии 8.x возникает ошибка сборки:

```
FAILURE: Build failed with an exception.
* What went wrong:
A problem occurred configuring project ':wifi_info_enhanced'.
> Could not create an instance of type com.android.build.api.variant.impl.LibraryVariantBuilderImpl.
   > Namespace not specified. Specify a namespace in the module's build file
```

Это происходит потому, что AGP 8.0+ требует обязательного указания `namespace` в `build.gradle` файле для всех модулей.

## Решение

### 1. Обновить build.gradle плагина

Файл: `android/build.gradle`

**Текущая конфигурация:**
```gradle
group 'team.moroz.wifi_info_enhanced'
version '1.1.0'

buildscript {
    ext.kotlin_version = '1.7.10'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.1'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    compileSdkVersion 33

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = '1.8'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        minSdkVersion 16
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk7:$kotlin_version"
}
```

**Новая конфигурация:**
```gradle
group 'team.moroz.wifi_info_enhanced'
version '1.1.0'

apply plugin: 'com.android.library'
apply plugin: 'kotlin-android'

android {
    namespace = 'team.moroz.wifi_info_enhanced'
    compileSdk 34

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        minSdk 16
    }
}

dependencies {
    implementation "org.jetbrains.kotlin:kotlin-stdlib-jdk8:2.2.0"
}
```

### 2. Обновить корневой build.gradle

Файл: `android/build.gradle` (корневой)

Добавить в блок `plugins`:
```gradle
plugins {
    id "com.android.library" version "8.6.1" apply false
    id "org.jetbrains.kotlin.android" version "2.2.0" apply false
}
```

### 3. Ключевые изменения

1. **Добавлен namespace**: `namespace = 'team.moroz.wifi_info_enhanced'`
2. **Обновлена версия AGP**: с 7.3.1 до 8.6.1
3. **Обновлена версия Kotlin**: с 1.7.10 до 2.2.0
4. **Обновлен compileSdk**: с 33 до 34
5. **Обновлена версия Java**: с 1.8 до 17
6. **Упрощена структура**: убраны лишние блоки `buildscript` и `rootProject.allprojects`

### 4. Применение изменений

После внесения изменений в исходный код плагина:

1. **Для немедленного исправления сборки** - применить те же изменения к кэшированной версии:
   ```
   /Users/alexandr/.pub-cache/hosted/pub.dev/wifi_info_enhanced-2.0.0/android/build.gradle
   ```

2. **Очистить кэш и пересобрать**:
   ```bash
   flutter clean
   flutter pub get
   flutter build android
   ```

### 5. Примечания

- `namespace` берется из `group` плагина: `team.moroz.wifi_info_enhanced`
- Это обязательное требование для AGP 8.0+
- Изменения нужны как в исходном коде (для будущих публикаций), так и в `.pub-cache` (для текущей сборки)
- После публикации новой версии плагина с исправлениями, можно будет убрать изменения из `.pub-cache`

## Связанные проекты

Этот плагин используется в проекте CAST (`/Users/alexandr/500na700/cast`) для получения информации о WiFi подключении в сервисе `DeviceStateService`.
