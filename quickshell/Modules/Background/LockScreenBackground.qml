import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

Item {
    id: root

    // Since WlSessionLockSurface doesn't provide a proper screen reference,
    // we'll use a simple approach: just display a wallpaper from any available screen
    
    // Internal state management
    property string transitionType: "fade"
    property real transitionProgress: 0
    readonly property real edgeSmoothness: Settings.data.wallpaper.transitionEdgeSmoothness
    readonly property var allTransitions: WallpaperService.allTransitions
    readonly property bool transitioning: transitionAnimation.running
    // Wipe direction: 0=left, 1=right, 2=up, 3=down
    property real wipeDirection: 0
    // Disc
    property real discCenterX: 0.5
    property real discCenterY: 0.5
    // Stripe
    property real stripesCount: 16
    property real stripesAngle: 0
    // Used to debounce wallpaper changes
    property string futureWallpaper: ""
    // Fillmode default is "crop"
    property real fillMode: 1
    property vector4d fillColor: Qt.vector4d(Settings.data.wallpaper.fillColor.r, Settings.data.wallpaper.fillColor.g, Settings.data.wallpaper.fillColor.b, 1)

    // Lock/Unlock transition properties
    property string currentLockTransitionType: "fade"
    property string currentUnlockTransitionType: "fade"
    property real lockTransitionProgress: 0
    property int lastLockShaderIndex: -1
    property int lastUnlockShaderIndex: -1

    function startTransition() {
        if (!transitioning && nextWallpaper.source != currentWallpaper.source)
            transitionAnimation.start();
    }

    function setWallpaperImmediate(source) {
        transitionAnimation.stop();
        transitionProgress = 0;
        currentWallpaper.source = source;
        nextWallpaper.source = "";
    }

    function setWallpaperWithTransition(source) {
        if (source != currentWallpaper.source) {
            if (transitioning) {
                // We are interrupting a transition
                transitionAnimation.stop();
                transitionProgress = 0;
                currentWallpaper.source = nextWallpaper.source;
                nextWallpaper.source = "";
            }
            nextWallpaper.source = source;
            startTransition();
        }
    }

    // Main method that actually trigger the wallpaper change
    function changeWallpaper() {
        // Get the transitionType from the settings
        transitionType = Settings.data.wallpaper.transitionType;
        if (transitionType == "random") {
            var index = Math.floor(Math.random() * allTransitions.length);
            transitionType = allTransitions[index];
        }
        // Ensure the transition type really exists
        if (transitionType !== "none" && !allTransitions.includes(transitionType))
            transitionType = "fade";

        switch (transitionType) {
        case "none":
            setWallpaperImmediate(futureWallpaper);
            break;
        case "wipe":
            wipeDirection = Math.random() * 4;
            setWallpaperWithTransition(futureWallpaper);
            break;
        case "disc":
            discCenterX = Math.random();
            discCenterY = Math.random();
            setWallpaperWithTransition(futureWallpaper);
            break;
        case "stripes":
            stripesCount = Math.round(Math.random() * 20 + 4);
            stripesAngle = Math.random() * 360;
            setWallpaperWithTransition(futureWallpaper);
            break;
        default:
            setWallpaperWithTransition(futureWallpaper);
            break;
        }
    }

    // Play unlock animation with random transition type
    function playUnlockAnimation() {
        // Choose a random transition different from the lock transition
        var shaderType = selectRandomUnlockShader();
        
        // Setup transition parameters based on type
        switch (shaderType) {
        case "wipe":
            wipeDirection = Math.random() * 4;
            break;
        case "disc":
            discCenterX = Math.random();
            discCenterY = Math.random();
            break;
        case "stripes":
            stripesCount = Math.round(Math.random() * 20 + 4);
            stripesAngle = Math.random() * 360;
            break;
        }
        
        // Update transition type for the unlock shader
        transitionType = shaderType;
        
        // Reverse the lock transition progress (1 -> 0) to hide the lockscreen
        lockTransitionProgress = 1;
        unlockAnimation.start();
    }

    function selectRandomShader() {
        // Select a random shader for lock transition
        // Avoid using the same shader as the last unlock
        var index = Math.floor(Math.random() * allTransitions.length);
        while (index === lastUnlockShaderIndex && allTransitions.length > 1) {
            index = Math.floor(Math.random() * allTransitions.length);
        }
        lastLockShaderIndex = index;
        currentLockTransitionType = allTransitions[index];
        return currentLockTransitionType;
    }

    function selectRandomUnlockShader() {
        // Select a random shader for unlock transition
        // Ensure it's different from the lock shader
        var index = Math.floor(Math.random() * allTransitions.length);
        while (index === lastLockShaderIndex && allTransitions.length > 1) {
            index = Math.floor(Math.random() * allTransitions.length);
        }
        lastUnlockShaderIndex = index;
        currentUnlockTransitionType = allTransitions[index];
        return currentUnlockTransitionType;
    }

    function playLockAnimation() {
        // Stop any ongoing wallpaper transition
        if (transitioning) {
            transitionAnimation.stop();
            currentWallpaper.source = nextWallpaper.source;
            nextWallpaper.source = "";
            transitionProgress = 0;
        }
        
        // Select a random shader for the lock transition
        var shaderType = selectRandomShader();
        
        // Setup transition parameters based on type
        switch (shaderType) {
        case "wipe":
            wipeDirection = Math.random() * 4;
            break;
        case "disc":
            discCenterX = Math.random();
            discCenterY = Math.random();
            break;
        case "stripes":
            stripesCount = Math.round(Math.random() * 20 + 4);
            stripesAngle = Math.random() * 360;
            break;
        }
        
        // Set both images to the current wallpaper
        // This creates a "reveal" effect with the same image
        nextWallpaper.source = currentWallpaper.source;
        
        // Reset progress and start lock animation
        lockTransitionProgress = 0;
        transitionType = shaderType;
        lockAnimation.start();
    }

    function loadWallpaper() {
        fillMode = WallpaperService.getFillModeUniform();
        
        // Try to get the first wallpaper from available screens
        // or use the desktop wallpaper as fallback
        var path = "";
        if (Quickshell.screens && Quickshell.screens.length > 0) {
            path = WallpaperService.getWallpaper(Quickshell.screens[0].name);
        }
        
        setWallpaperImmediate(path);
    }

    // On startup assign wallpaper
    Component.onCompleted: {
        loadWallpaper();
        // Also schedule a check in case services weren't ready
        loadWallpaperTimer.start();
    }
    
    Timer {
        id: loadWallpaperTimer
        interval: 100
        repeat: false
        onTriggered: {
            // If wallpaper is still empty, try again
            if (currentWallpaper.source === "") {
                loadWallpaper();
            }
        }
    }
    anchors.fill: parent

    Connections {
        function onFillModeChanged() {
            fillMode = WallpaperService.getFillModeUniform();
        }

        target: Settings.data.wallpaper
    }

    // External state management - listen to wallpaper changes
    Connections {
        function onWallpaperChanged(screenName, path) {
            if (screen && screenName === screen.name) {
                // Update wallpaper display
                futureWallpaper = path;
                debounceTimer.restart();
            }
        }

        target: WallpaperService
    }

    Timer {
        id: debounceTimer

        interval: 333
        running: false
        repeat: false
        onTriggered: {
            changeWallpaper();
        }
    }

    Image {
        id: currentWallpaper

        source: ""
        smooth: true
        mipmap: false
        visible: false
        cache: false
        // currentWallpaper should not be asynchronous to avoid flickering when swapping next to current.
        asynchronous: false
    }

    Image {
        id: nextWallpaper

        source: ""
        smooth: true
        mipmap: false
        visible: false
        cache: false
        asynchronous: true
    }

    // Fade or None transition shader
    ShaderEffect {
        id: fadeShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.transitionProgress
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        visible: transitionType === "fade" || transitionType === "none"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_fade.frag.qsb")
    }

    // Wipe transition shader
    ShaderEffect {
        id: wipeShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.transitionProgress
        property real smoothness: root.edgeSmoothness
        property real direction: root.wipeDirection
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        visible: transitionType === "wipe"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_wipe.frag.qsb")
    }

    // Disc reveal transition shader
    ShaderEffect {
        id: discShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.transitionProgress
        property real smoothness: root.edgeSmoothness
        property real aspectRatio: root.width / root.height
        property real centerX: root.discCenterX
        property real centerY: root.discCenterY
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        visible: transitionType === "disc"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_disc.frag.qsb")
    }

    // Diagonal stripes transition shader
    ShaderEffect {
        id: stripesShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.transitionProgress
        property real smoothness: root.edgeSmoothness
        property real aspectRatio: root.width / root.height
        property real stripeCount: root.stripesCount
        property real angle: root.stripesAngle
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        visible: transitionType === "stripes"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_stripes.frag.qsb")
    }

    // Global lock/unlock transition shader effects (full-screen overlay)
    // These layers create the dramatic reveal/hide effect when locking and unlocking
    
    // Lock/Unlock Fade transition shader
    ShaderEffect {
        id: lockTransitionFadeShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.lockTransitionProgress
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        z: 100
        visible: lockTransitionProgress > 0 && lockTransitionProgress < 1 && currentLockTransitionType === "fade"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_fade.frag.qsb")
    }

    // Lock/Unlock Wipe transition shader
    ShaderEffect {
        id: lockTransitionWipeShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.lockTransitionProgress
        property real smoothness: root.edgeSmoothness
        property real direction: root.wipeDirection
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        z: 100
        visible: lockTransitionProgress > 0 && lockTransitionProgress < 1 && currentLockTransitionType === "wipe"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_wipe.frag.qsb")
    }

    // Lock/Unlock Disc transition shader
    ShaderEffect {
        id: lockTransitionDiscShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.lockTransitionProgress
        property real smoothness: root.edgeSmoothness
        property real aspectRatio: root.width / root.height
        property real centerX: root.discCenterX
        property real centerY: root.discCenterY
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        z: 100
        visible: lockTransitionProgress > 0 && lockTransitionProgress < 1 && currentLockTransitionType === "disc"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_disc.frag.qsb")
    }

    // Lock/Unlock Stripes transition shader
    ShaderEffect {
        id: lockTransitionStripesShader

        property variant source1: currentWallpaper
        property variant source2: nextWallpaper
        property real progress: root.lockTransitionProgress
        property real smoothness: root.edgeSmoothness
        property real aspectRatio: root.width / root.height
        property real stripeCount: root.stripesCount
        property real angle: root.stripesAngle
        // Fill mode properties
        property real fillMode: root.fillMode
        property vector4d fillColor: root.fillColor
        property real imageWidth1: source1.sourceSize.width
        property real imageHeight1: source1.sourceSize.height
        property real imageWidth2: source2.sourceSize.width
        property real imageHeight2: source2.sourceSize.height
        property real screenWidth: width
        property real screenHeight: height

        anchors.fill: parent
        z: 100
        visible: lockTransitionProgress > 0 && lockTransitionProgress < 1 && currentLockTransitionType === "stripes"
        fragmentShader: Qt.resolvedUrl("../../Shaders/qsb/wp_stripes.frag.qsb")
    }

    // Animation for the transition progress
    NumberAnimation {
        id: transitionAnimation

        target: root
        property: "transitionProgress"
        from: 0
        to: 1
        // The stripes shader feels faster visually, we make it a bit slower here.
        duration: transitionType == "stripes" ? Settings.data.wallpaper.transitionDuration * 1.6 : Settings.data.wallpaper.transitionDuration
        easing.type: Easing.InOutCubic
        onFinished: {
            // Swap images after transition completes
            currentWallpaper.source = nextWallpaper.source;
            nextWallpaper.source = "";
            transitionProgress = 0;
        }
    }

    // Animation for lock transition (reveals lockscreen)
    NumberAnimation {
        id: lockAnimation

        target: root
        property: "lockTransitionProgress"
        from: 0
        to: 1
        duration: 600
        easing.type: Easing.InOutCubic
        onFinished: {
            // After lock animation, keep showing the locked state
            lockTransitionProgress = 1;
        }
    }

    // Animation for unlock transition (hides lockscreen)
    NumberAnimation {
        id: unlockAnimation

        target: root
        property: "lockTransitionProgress"
        from: 1
        to: 0
        duration: 600
        easing.type: Easing.InOutCubic
        onFinished: {
            // After unlock animation completes, reset the lock transition
            lockTransitionProgress = 0;
            transitionType = "none";
        }
    }

}
