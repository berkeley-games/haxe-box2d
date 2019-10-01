package ;

import Std;
import box2D.collision.shapes.B2PolygonShape;
import box2D.common.math.B2Vec2;
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2FixtureDef;
import box2D.dynamics.B2World;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.FPS;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import openfl.events.MouseEvent;

class Main extends Sprite
{
	private var world:B2World;
	private var worldContainer:Sprite;
	private var totalBodies:Int = 0;
	private var phyScale:Float = 1 / 30;
	private var timeStep:Float;

	public function new()
	{
		super();

		stage.frameRate = 30;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;

		timeStep = 1 / stage.frameRate;

		world = new B2World(new B2Vec2(0, 10), true);

		worldContainer = new Sprite();
		stage.addChild(worldContainer);

		var background:Shape = new Shape();
		background.graphics.beginFill(stage.color);
		background.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
		background.graphics.endFill();
		worldContainer.addChild(background);

		var wallThickness:Int = 25;
		generateBox(stage.stageWidth / 2, -wallThickness, stage.stageWidth, wallThickness, false);
		generateBox(stage.stageWidth / 2, stage.stageHeight + wallThickness, stage.stageWidth, wallThickness, false);
		generateBox(-wallThickness, stage.stageHeight / 2, wallThickness, stage.stageHeight, false);
		generateBox(stage.stageWidth + wallThickness, stage.stageHeight / 2, wallThickness, stage.stageHeight, false);

		addEventListener(Event.ENTER_FRAME, onEnterFrame);
		worldContainer.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);

		var fps:FPS = new FPS(5, 5, 0xFFFFFF);
		stage.addChild(fps);
	}

	private function onMouseDown(event:MouseEvent):Void
	{
		worldContainer.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		worldContainer.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}

	private function onMouseMove(event:MouseEvent):Void
	{
		generateBox(event.stageX, event.stageY, 25, 23, true);
	}

	private function onMouseUp(event:MouseEvent):Void
	{
		var target:Sprite = cast event.target;
		if(target.name.indexOf("Box") > -1) removeBox(target);

		worldContainer.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
		worldContainer.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
	}

	private function onEnterFrame(event:Event):Void
	{
		world.step(timeStep, 5, 2);
		world.drawDebugData();

		updateGraphics();

		world.clearForces();
	}

	private function updateGraphics ():Void
	{
		var iter = new BoxIter(world);

		for(body in iter)
		{
			try
			{
				if(Std.is(body.getUserData(), Sprite))
				{
					var sprite:Sprite = cast body.getUserData();
					sprite.x = body.getPosition().x / phyScale;
					sprite.y = body.getPosition().y / phyScale;
					sprite.rotation = body.getAngle() * 180 / Math.PI;
				}
			}
			catch (unknown:Dynamic) { trace(unknown); }
		}
	}

	private function generateBox(x:Float, y:Float, width:Float, height:Float, dynamicBody:Bool):Void
	{
		var bodyDefinition = new B2BodyDef();
		bodyDefinition.position.set(x * phyScale, y * phyScale);
		bodyDefinition.allowSleep = true;
		bodyDefinition.fixedRotation = false;

		if(dynamicBody)
		{
			var angle:Int = Math.floor(Math.random() * 360);
			bodyDefinition.type = B2Body.b2_dynamicBody;
			bodyDefinition.angle = angle;
		}

		var polygon = new B2PolygonShape();
		polygon.setAsBox((width / 2) * phyScale, (height / 2) * phyScale);

		var fixtureDefinition = new B2FixtureDef();
		fixtureDefinition.shape = polygon;
		fixtureDefinition.friction = 0.2;
		fixtureDefinition.density = 1;

		var body = world.createBody(bodyDefinition);
		body.createFixture(fixtureDefinition);

		if(dynamicBody)
		{
			var bitmap:Bitmap = new Bitmap(Assets.getBitmapData("res/box2d.png"));
			bitmap.x = -(bitmap.width / 2);
			bitmap.y = -(bitmap.height / 2);

			var boxContainer:Sprite = new Sprite();
			boxContainer.addChild(bitmap);
			body.setUserData(boxContainer);
			boxContainer.name = "Box" + Std.string(totalBodies);
			worldContainer.addChild(boxContainer);
			totalBodies++;
		}
		else
		{
			body.setUserData("static");
		}
	}

	private function removeBox(target:Sprite):Void
	{
		var iter = new BoxIter(world);

		for (body in iter)
		{
			if (Std.is(body.getUserData(), Sprite))
			{
				var sprite:Sprite = cast body.getUserData();

				if(sprite.name == target.name)
				{
					world.destroyBody(body);
					target.parent.removeChild(target);
					target = null;
					break;
				}
			}
		}
	}
}

class BoxIter
{
	var current:B2Body;
	var count:Int;
	var first:Bool;

	public function new(world:B2World)
	{
		this.current = world.getBodyList();
		this.count = world.getBodyCount();
		this.first = true;
	}

	public function hasNext()
	{
		try
		{
			if(Std.is(current.getNext(), B2Body)) return true;
		}
		catch (unkown:Dynamic) {}

		return false;
	}

	public function next()
	{
		if(first)
		{
			first = false;
			return current;
		}

		if(current.getNext != null)
		{
			current = current.getNext();
			return current;
		}
		else
		{
			return current;
		}
	}
}