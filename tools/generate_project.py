#!/usr/bin/env python3
"""Generate FishingNow.xcodeproj/project.pbxproj (+ workspace + scheme).

Modelled on the proven SafeMeet project.pbxproj already in this workspace
(same objectVersion, same build-settings shape), extended with a second
native target for the Watch app and an "Embed Watch Content" phase on the
iPhone target, so installing the iPhone app installs the Watch app.

Run: python3 tools/generate_project.py
"""
import pathlib

ROOT = pathlib.Path(__file__).parent.parent
_counter = [0x100]

def uid():
    _counter[0] += 1
    return f"{_counter[0]:024X}"

# --- file inventory -------------------------------------------------------
# (path relative to project root, group, lastKnownFileType)
IOS_FILES = [
    ("FishingNow/FishingNowApp.swift", "sourcecode.swift"),
    ("FishingNow/ContentView.swift", "sourcecode.swift"),
    ("FishingNow/PhoneStore.swift", "sourcecode.swift"),
    ("FishingNow/Assets.xcassets", "folder.assetcatalog"),
]
WATCH_FILES = [
    ("FishingNowWatch Watch App/FishingNowWatchApp.swift", "sourcecode.swift"),
    ("FishingNowWatch Watch App/GameView.swift", "sourcecode.swift"),
    ("FishingNowWatch Watch App/WatchViews.swift", "sourcecode.swift"),
    ("FishingNowWatch Watch App/WatchStore.swift", "sourcecode.swift"),
    ("FishingNowWatch Watch App/Assets.xcassets", "folder.assetcatalog"),
]
SHARED_FILES = [
    ("Shared/Fish.swift", "sourcecode.swift"),
    ("Shared/FishData.swift", "sourcecode.swift"),
    ("Shared/GameEngine.swift", "sourcecode.swift"),
]

# allocate ids
proj = uid(); ios_target = uid(); watch_target = uid()
ios_product = uid(); watch_product = uid()
main_group = uid(); ios_group = uid(); watch_group = uid(); shared_group = uid(); products_group = uid()
ios_sources = uid(); ios_frameworks = uid(); ios_resources = uid(); ios_embed_watch = uid()
watch_sources = uid(); watch_frameworks = uid(); watch_resources = uid()
proj_cfg_list = uid(); ios_cfg_list = uid(); watch_cfg_list = uid()
proj_debug = uid(); proj_release = uid()
ios_debug = uid(); ios_release = uid(); watch_debug = uid(); watch_release = uid()
dep = uid(); proxy = uid()

file_refs = {}   # path -> (id, name)
build_files = {} # (target, path) -> id
for path, ftype in IOS_FILES + WATCH_FILES + SHARED_FILES:
    file_refs[path] = (uid(), pathlib.Path(path).name)
for target, files in (("ios", IOS_FILES + SHARED_FILES), ("watch", WATCH_FILES + SHARED_FILES)):
    for path, ftype in files:
        build_files[(target, path)] = uid()
watch_product_build = uid()  # watch .app in the iOS Embed Watch Content phase

def ref(path):
    fid, name = file_refs[path]
    return f'{fid} /* {name} */'
def bf(target, path):
    return f'{build_files[(target, path)]} /* {pathlib.Path(path).name} in {"Sources" if path.endswith(".swift") else "Resources"} */'

def build_file_section():
    out = ["/* Begin PBXBuildFile section */"]
    for (target, path), bid in build_files.items():
        kind = "Sources" if path.endswith(".swift") else "Resources"
        out.append(f'\t\t{bid} /* {pathlib.Path(path).name} in {kind} */ = {{isa = PBXBuildFile; fileRef = {ref(path)}; }};')
    out.append("/* End PBXBuildFile section */\n")
    return "\n".join(out)

def file_ref_section():
    out = ["/* Begin PBXFileReference section */"]
    for path, ftype in IOS_FILES + WATCH_FILES + SHARED_FILES:
        fid, name = file_refs[path]
        out.append(f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {name}; sourceTree = "<group>"; }};')
    out.append(f'\t\t{ios_product} /* FishingNow.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = FishingNow.app; sourceTree = BUILT_PRODUCTS_DIR; }};')
    out.append(f'\t\t{watch_product} /* FishingNowWatch Watch App.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "FishingNowWatch Watch App.app"; sourceTree = BUILT_PRODUCTS_DIR; }};')
    out.append("/* End PBXFileReference section */\n")
    return "\n".join(out)

def target_settings(bundle, name, device_family, sdk, deploy_key, deploy_val, extra=""):
    return f"""ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = "{name}";
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {bundle};
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "{device_family}";{extra}"""

pbx = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

{build_file_section()}
{file_ref_section()}
/* Begin PBXFrameworksBuildPhase section */
\t\t{ios_frameworks} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{watch_frameworks} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group} /*  */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{ios_group} /* FishingNow */,
\t\t\t\t{watch_group} /* FishingNowWatch Watch App */,
\t\t\t\t{shared_group} /* Shared */,
\t\t\t\t{products_group} /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{ios_group} /* FishingNow */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join(chr(9)+chr(9)+chr(9)+ref(p)+" ," for p, _ in IOS_FILES)}
\t\t\t);
\t\t\tpath = FishingNow;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{watch_group} /* FishingNowWatch Watch App */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join(chr(9)+chr(9)+chr(9)+ref(p)+" ," for p, _ in WATCH_FILES)}
\t\t\t);
\t\t\tpath = "FishingNowWatch Watch App";
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{shared_group} /* Shared */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join(chr(9)+chr(9)+chr(9)+ref(p)+" ," for p, _ in SHARED_FILES)}
\t\t\t);
\t\t\tpath = Shared;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{products_group} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{ios_product} /* FishingNow.app */,
\t\t\t\t{watch_product} /* FishingNowWatch Watch App.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{ios_target} /* FishingNow */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {ios_cfg_list} /* Build configuration list for PBXNativeTarget "FishingNow" */;
\t\t\tbuildPhases = (
\t\t\t\t{ios_sources} /* Sources */,
\t\t\t\t{ios_frameworks} /* Frameworks */,
\t\t\t\t{ios_resources} /* Resources */,
\t\t\t\t/* EXPERIMENT: Embed Watch Content phase temporarily detached
\t\t\t\t   to test whether its reference to the Watch product is what
\t\t\t\t   makes Xcode add a CopyAndPreserveArchs task to the Watch
\t\t\t\t   target's own build. The phase object still exists below,
\t\t\t\t   unreferenced. Restore by re-adding the line. */
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = FishingNow;
\t\t\tproductName = FishingNow;
\t\t\tproductReference = {ios_product} /* FishingNow.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{watch_target} /* FishingNowWatch Watch App */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {watch_cfg_list} /* Build configuration list for PBXNativeTarget "FishingNowWatch Watch App" */;
\t\t\tbuildPhases = (
\t\t\t\t{watch_sources} /* Sources */,
\t\t\t\t{watch_frameworks} /* Frameworks */,
\t\t\t\t{watch_resources} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = "FishingNowWatch Watch App";
\t\t\tproductName = "FishingNowWatch Watch App";
\t\t\tproductReference = {watch_product} /* FishingNowWatch Watch App.app */;
\t\t\tproductType = "com.apple.product-type.application.watchapp2";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastSwiftUpdateCheck = 1700;
\t\t\t\tLastUpgradeCheck = 1700;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{ios_target} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 17.0;
\t\t\t\t\t}};
\t\t\t\t\t{watch_target} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 17.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_cfg_list} /* Build configuration list for PBXProject "FishingNow" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{ios_target} /* FishingNow */,
\t\t\t\t{watch_target} /* FishingNowWatch Watch App */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{ios_resources} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{bf("ios", "FishingNow/Assets.xcassets")},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{watch_resources} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{bf("watch", "FishingNowWatch Watch App/Assets.xcassets")},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{ios_sources} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(chr(9)+chr(9)+chr(9)+bf("ios", p)+" ," for p, _ in IOS_FILES if p.endswith(".swift"))}
{chr(10).join(chr(9)+chr(9)+chr(9)+bf("ios", p)+" ," for p, _ in SHARED_FILES)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{watch_sources} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(chr(9)+chr(9)+chr(9)+bf("watch", p)+" ," for p, _ in WATCH_FILES if p.endswith(".swift"))}
{chr(10).join(chr(9)+chr(9)+chr(9)+bf("watch", p)+" ," for p, _ in SHARED_FILES)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{proj_debug} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{proj_release} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu17;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{ios_debug} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{target_settings("com.a2sandoval.fishingnow", "Fishing Now", "1,2", "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET", "17.0")}
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{ios_release} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{target_settings("com.a2sandoval.fishingnow", "Fishing Now", "1,2", "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET", "17.0")}
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{watch_debug} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{target_settings("com.a2sandoval.fishingnow.watchkitapp", "Fishing Now", "4", "watchos", "WATCHOS_DEPLOYMENT_TARGET", "10.0")}
\t\t\t\tINFOPLIST_KEY_WKApplication = YES;
 				INFOPLIST_KEY_WKCompanionAppBundleIdentifier = com.a2sandoval.fishingnow;
\t\t\t\tSDKROOT = watchos;
\t\t\t\tSUPPORTED_PLATFORMS = watchos;
\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;
\t\t\t\tSKIP_INSTALL = YES;
 				ONLY_ACTIVE_ARCH = YES;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{watch_release} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\t{target_settings("com.a2sandoval.fishingnow.watchkitapp", "Fishing Now", "4", "watchos", "WATCHOS_DEPLOYMENT_TARGET", "10.0")}
\t\t\t\tINFOPLIST_KEY_WKApplication = YES;
 				INFOPLIST_KEY_WKCompanionAppBundleIdentifier = com.a2sandoval.fishingnow;
\t\t\t\tSDKROOT = watchos;
\t\t\t\tSUPPORTED_PLATFORMS = watchos;
\t\t\t\tWATCHOS_DEPLOYMENT_TARGET = 10.0;
\t\t\t\tSKIP_INSTALL = YES;
 				ONLY_ACTIVE_ARCH = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{proj_cfg_list} /* Build configuration list for PBXProject "FishingNow" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{proj_debug} /* Debug */,
\t\t\t\t{proj_release} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{ios_cfg_list} /* Build configuration list for PBXNativeTarget "FishingNow" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{ios_debug} /* Debug */,
\t\t\t\t{ios_release} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{watch_cfg_list} /* Build configuration list for PBXNativeTarget "FishingNowWatch Watch App" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{watch_debug} /* Debug */,
\t\t\t\t{watch_release} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {proj} /* Project object */;
}}
"""

outdir = ROOT / "FishingNow.xcodeproj"
(outdir / "project.pbxproj").write_text(pbx)
print(f"wrote {outdir / 'project.pbxproj'} ({len(pbx)} bytes)")

(ROOT / "FishingNow.xcodeproj" / "project.xcworkspace" / "contents.xcworkspacedata").write_text(
    '<?xml version="1.0" encoding="UTF-8"?>\n<Workspace version="1.0">\n'
    '   <FileRef location="self:"></FileRef>\n</Workspace>\n')

scheme_dir = ROOT / "FishingNow.xcodeproj" / "xcshareddata" / "xcschemes"
scheme_dir.mkdir(parents=True, exist_ok=True)
(scheme_dir / "FishingNow.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1700" version="1.3">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ios_target}" BuildableName="FishingNow.app" BlueprintName="FishingNow" ReferencedContainer="container:FishingNow.xcodeproj"/>
         </BuildActionEntry>
         <!-- The Watch app is NOT listed here on purpose: if the iOS
              target has an explicit dependency on it, Xcode plans the
              Watch executable twice (link step plus CopyAndPreserveArchs)
              and fails with "Multiple commands produce ...". The Watch
              app is built first, as its own scheme, into the same
              derived-data folder; the iPhone build's "Embed Watch
              Content" phase then copies the already-built .app. -->
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"/>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ios_target}" BuildableName="FishingNow.app" BlueprintName="FishingNow" ReferencedContainer="container:FishingNow.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
''')
# Separate scheme for the Watch app alone. xcodebuild requires -scheme (not
# -target) when -derivedDataPath is given, and the CI workflow builds the
# Watch app first into the shared derived-data folder so the iPhone build's
# "Embed Watch Content" phase can copy it.
(scheme_dir / "FishingNowWatch Watch App.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1700" version="1.3">
   <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
            <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{watch_target}" BuildableName="FishingNowWatch Watch App.app" BlueprintName="FishingNowWatch Watch App" ReferencedContainer="container:FishingNow.xcodeproj"/>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"/>
   <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
      <BuildableProductRunnable runnableDebuggingMode="0">
         <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{watch_target}" BuildableName="FishingNowWatch Watch App.app" BlueprintName="FishingNowWatch Watch App" ReferencedContainer="container:FishingNow.xcodeproj"/>
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
''')
print("wrote workspace + scheme")
