"""يجهّز مشروع أندرويد المولَّد بـ flutter create: الأذونات + core library desugaring
(مطلوب لمكتبة الإشعارات). شغّله من جذر المشروع: python3 tool/android_setup.py"""
import pathlib
import re

root = pathlib.Path('android/app')

manifest = root / 'src/main/AndroidManifest.xml'
s = manifest.read_text()
for perm in ('INTERNET', 'POST_NOTIFICATIONS'):
    if f'android.permission.{perm}' not in s:
        s = s.replace('<application', f'<uses-permission android:name="android.permission.{perm}"/>\n    <application', 1)
manifest.write_text(s)

kts, groovy = root / 'build.gradle.kts', root / 'build.gradle'
if kts.exists():
    g = kts.read_text()
    if 'isCoreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'(compileOptions\s*\{)', r'\1\n        isCoreLibraryDesugaringEnabled = true', g, count=1)
    if 'coreLibraryDesugaring(' not in g:
        g += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    kts.write_text(g)
elif groovy.exists():
    g = groovy.read_text()
    if 'coreLibraryDesugaringEnabled' not in g:
        g = re.sub(r'(compileOptions\s*\{)', r'\1\n        coreLibraryDesugaringEnabled true', g, count=1)
    if 'coreLibraryDesugaring ' not in g:
        g += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    groovy.write_text(g)
else:
    raise SystemExit('لم أجد android/app/build.gradle(.kts)')
print('android setup done')
