"""يجهّز مشروع أندرويد المولَّد بـ flutter create:
الأذونات + core library desugaring + أيقونة الإشعار (ic_stat).
شغّله من جذر المشروع: python3 tool/android_setup.py"""
import pathlib
import re

root = pathlib.Path('android/app')

# ---- الأذونات
manifest = root / 'src/main/AndroidManifest.xml'
s = manifest.read_text()
for perm in ('INTERNET', 'POST_NOTIFICATIONS'):
    if f'android.permission.{perm}' not in s:
        s = s.replace('<application', f'<uses-permission android:name="android.permission.{perm}"/>\n    <application', 1)
manifest.write_text(s)

# ---- desugaring
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

# ---- أيقونة الإشعار (أحادية اللون) + منع حذفها عند تصغير الموارد
res = root / 'src/main/res'
(res / 'drawable').mkdir(parents=True, exist_ok=True)
(res / 'raw').mkdir(parents=True, exist_ok=True)
(res / 'drawable/ic_stat.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
  <path android:fillColor="#FFFFFFFF"
      android:pathData="M3.5,18.5l6,-6l4,4L22,6.92L20.59,5.5l-7.09,7.09l-4,-4L2,16.99z"/>
</vector>
''')
(res / 'raw/keep.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat" />
''')
print('android setup done')
