import flixel.math.FlxBasePoint;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxTiledSprite;

var scrollingSky:FlxTiledSprite;

var rainShader:RuntimeShader;
var rainShaderStartIntensity:Float;
var rainShaderEndIntensity:Float;
var songLength:Float = 0;

var lightsStop:Bool = false;
var changeInterval:Int = 8;
var lastChange:Int = 0;

var carWaiting:Bool = false;
var carInterruptable:Bool = true;
var car2Interruptable:Bool = true;
var paperInterruptable:Bool = true;

function createPost() {
	resetCar(true, true);
	
	stage.add(scrollingSky = new FlxTiledSprite(Paths.image('phillyStreets/phillySkybox', 'weekend1'), 2922, 718, true, false));
	scrollingSky.scrollFactor.set(.1, .1);
	scrollingSky.setPosition(-650, -375);
	scrollingSky.scale.set(.65, .65);
	scrollingSky.zIndex = 10;

	rainShader = new RuntimeShader('rain');
	rainShader.setFloatArray('uScreenResolution', [FlxG.width, FlxG.height]);
	rainShader.setFloatArray('uCameraBounds', [0, 0, FlxG.width, FlxG.height]);
	game.camGame.filters = [new ShaderFilter(rainShader)];
	
	switch (PlayState.song.path) {
		case 'darnell':
			rainShaderStartIntensity = 0;
			rainShaderEndIntensity = .1;
		case 'lit-up':
			rainShaderStartIntensity = .1;
			rainShaderEndIntensity = .2;
		case '2hot':
			rainShaderStartIntensity = .2;
			rainShaderEndIntensity = .4;
	}
	songLength = PlayState.song.songLength ?? 0;
	rainShader.setFloat('uScale', FlxG.height / 200);
	rainShader.setFloat('uIntensity', rainShaderStartIntensity);
	rainShader.setFloatArray('uRainColor', [0x66 / 0xff, 0x80 / 0xff, 0xcc / 0xff]);

	for (name => prop in stage.props) {
		if (!StringTools.endsWith(name, '_lightmap')) continue;
		prop.blend = BlendMode.ADD;
		prop.alpha = .6;
	}

	stage.sortZIndex();
}

function update(elapsed, paused) {
	if (paused) return;

	if (scrollingSky != null)
		scrollingSky.scrollX -= elapsed * 22;

	var cam:FlxCamera = game.camGame;
	var time:Float = conductor.songPosition / 1000;
	var rainIntensity:Float = FlxMath.remapToRange(conductor.songPosition, 0, songLength, rainShaderStartIntensity, rainShaderEndIntensity);
	rainShader.setFloatArray('uCameraBounds', [cam.viewLeft, cam.viewTop, cam.viewRight, cam.viewBottom]);
	rainShader.setFloat('uIntensity', rainIntensity);
	rainShader.setFloat('uTime', time);
}

function beatHit(beat) {
	var canChangeLights:Bool = (beat == (lastChange + changeInterval));

	if (FlxG.random.bool(10) && !canChangeLights && carInterruptable) {
		if(lightsStop == false)
			driveCar(stage.getProp('phillyCars'));
		else
			driveCarLights(stage.getProp('phillyCars'));
	}

	if (FlxG.random.bool(10) && !canChangeLights && car2Interruptable && !lightsStop)
		driveCarBack(stage.getProp('phillyCars2'));

	if (canChangeLights)
		changeLights(beat);
}

function changeLights(beat) {
	lastChange = beat;
	lightsStop = !lightsStop;

	if (lightsStop) {
		stage.getProp('phillyTraffic').animation.play('tored');
		changeInterval = 20;
	} else {
		stage.getProp('phillyTraffic').animation.play('togreen');
		changeInterval = 30;

		if (carWaiting == true)
			finishCarLights(stage.getProp('phillyCars'));
	}
}

function resetCar(left:Bool, right:Bool) {
	if (left) {
		carWaiting = false;
		carInterruptable = true;
		var cars = stage.getProp('phillyCars');
		if (cars != null) {
			FlxTween.cancelTweensOf(cars);
			cars.x = 1200;
			cars.y = 818;
			cars.angle = 0;
		}
	}

	if (right) {
		car2Interruptable = true;
		var cars2 = stage.getProp('phillyCars2');
		if (cars2 != null) {
			FlxTween.cancelTweensOf(cars2);
			cars2.x = 1200;
			cars2.y = 818;
			cars2.angle = 0;
		}
	}
}

function carVariantDuration(variant:Int) {
	// set different values of speed for the car types
	return switch (variant) {
		case 1: FlxG.random.float(1, 1.7);
		case 2: FlxG.random.float(0.6, 1.2);
		case 3: FlxG.random.float(1.5, 2.5);
		case 4: FlxG.random.float(1.5, 2.5);
		default: 2;
	}
}

function driveCar(sprite:FlxSprite) {
	carInterruptable = false;
	FlxTween.cancelTweensOf(sprite);

	var variant:Int = FlxG.random.int(1,4);
	sprite.playAnimation('car' + variant);

	// random arbitrary values for getting the cars in place
	// could just add them to the points but im LAZY!!!!!!
	var offset:Array<Float> = [306.6, 168.3];
	// start/end rotation
	var rotations:Array<Int> = [-8, 18];
	// the path to move the car on
	var path:Array<FlxBasePoint> = [
		FlxBasePoint.get(1570 - offset[0], 1049 - offset[1] - 30),
		FlxBasePoint.get(2400 - offset[0], 980 - offset[1] - 50),
		FlxBasePoint.get(3102 - offset[0], 1127 - offset[1] + 40)
	];

	var duration:Float = carVariantDuration(variant);
	FlxTween.angle(sprite, rotations[0], rotations[1], duration, null);
	FlxTween.quadPath(sprite, path, duration, true, {
		onComplete: (_) -> { carInterruptable = true; }
	});
}

function driveCarBack(sprite:FlxSprite) {
	car2Interruptable = false;
	FlxTween.cancelTweensOf(sprite);

	var variant:Int = FlxG.random.int(1,4);
	sprite.playAnimation('car' + variant);

	var offset:Array<Float> = [306.6, 168.3];
	var rotations:Array<Int> = [18, -8];
	
	var path:Array<FlxBasePoint> = [
		FlxBasePoint.get(3102 - offset[0], 1127 - offset[1] + 60),
		FlxBasePoint.get(2400 - offset[0], 980 - offset[1] - 30),
		FlxBasePoint.get(1570 - offset[0], 1049 - offset[1] - 10)
	];

	var duration:Float = carVariantDuration(variant);
	FlxTween.angle(sprite, rotations[0], rotations[1], duration);
	FlxTween.quadPath(sprite, path, duration, true, {
		onComplete: (_) -> { car2Interruptable = true; }
	});
}

function driveCarLights(sprite:FlxSprite) {
	carInterruptable = false;
	FlxTween.cancelTweensOf(sprite);

	var variant:Int = FlxG.random.int(1,4);
	sprite.playAnimation('car' + variant);

	var rotations:Array<Int> = [-7, -5];
	var offset:Array<Float> = [306.6, 168.3];

	var path:Array<FlxBasePoint> = [
		FlxBasePoint.get(1500 - offset[0] - 20, 1049 - offset[1] - 20),
		FlxBasePoint.get(1770 - offset[0] - 80, 994 - offset[1] + 10),
		FlxBasePoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15)
	];

	var duration:Float = carVariantDuration(variant);
	FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.cubeOut});
	FlxTween.quadPath(sprite, path, duration, true, {
		ease: FlxEase.cubeOut,
		onComplete: (_) -> {
			carWaiting = true;
			if (lightsStop == false) finishCarLights(sprite);
		}
    });
}

function finishCarLights(sprite:FlxSprite) {
	carWaiting = false;
	var duration:Float = FlxG.random.float(1.8, 3);
	var rotations:Array<Int> = [-5, 18];
	var offset:Array<Float> = [306.6, 168.3];
	var startdelay:Float = FlxG.random.float(0.2, 1.2);

	var path:Array<FlxBasePoint> = [
		FlxBasePoint.get(1950 - offset[0] - 80, 980 - offset[1] + 15),
		FlxBasePoint.get(2400 - offset[0], 980 - offset[1] - 50),
		FlxBasePoint.get(3102 - offset[0], 1127 - offset[1] + 40)
	];

	FlxTween.angle(sprite, rotations[0], rotations[1], duration, {ease: FlxEase.sineIn, startDelay: startdelay});
	FlxTween.quadPath(sprite, path, duration, true, {
		ease: FlxEase.sineIn,
		startDelay: startdelay,
		onComplete: (_) -> { carInterruptable = true; }
	});
}