import json, pathlib, subprocess, time

def run(*args):
    subprocess.run(args,check=True)

devices=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','--json']))['devices']
iphone=next(d for key,rows in devices.items() if 'iOS' in key for d in rows if d['name'].startswith('iPhone'))
pathlib.Path('build').mkdir(exist_ok=True)
run('xcodebuild','test','-project','Doggos.xcodeproj','-scheme','Doggos','-destination',f"platform=iOS Simulator,id={iphone['udid']}",'-derivedDataPath','build/DerivedData','-resultBundlePath','build/DoggosTests.xcresult','CODE_SIGNING_ALLOWED=NO')
run('xcrun','simctl','bootstatus',iphone['udid'],'-b')
run('xcrun','simctl','install',iphone['udid'],'build/DerivedData/Build/Products/Debug-iphonesimulator/Doggos.app')
run('xcrun','simctl','launch',iphone['udid'],'it.thisable.doggos')
# Wait for the simulator's launch animation before capturing the actual screen.
time.sleep(5)
run('xcrun','simctl','io',iphone['udid'],'screenshot','build/doggos-iphone.png')
