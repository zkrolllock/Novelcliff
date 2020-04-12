/**
Container of game Areas, receiving user input signals,
translating those to game logic.
*/
module novelcliff.core.game;

import novelcliff.core.base;
import novelcliff.core.renderer;
import novelcliff.core.area;
import novelcliff.core.parser;
import novelcliff.core.interfaces;
import novelcliff.core.enums;

/**
Container of game Areas, receiving user input signals,
translating those to game logic.
*/
class Game : IAreaListContainer
{
private:
	// Reference to user interface
	IUserInterface _ui;

	LivingObject player;
	Renderer _renderer;
    Area[] areas;
	size_t activeAreaId;

	// Same size as InputSignal enum, initially all false.
	// Required in order to register multiple input signals at once
	// (e.g. perform Move left + Jump simultaneousle)
	bool[12] receivedSignals;

	// The amount of coins collected by the player during current game
	uint _coinsCollected;

	void handleInput()
	{
		if (receivedSignals[InputSignal.RIGHT_PRESS])
		{
			if (player.direction != Direction.RIGHT)
			{
				player.direction = Direction.RIGHT;
			}
			player.isMovingHorizontally = true;
		}
		if (receivedSignals[InputSignal.RIGHT_RELEASE])
		{
			if (player.direction == Direction.RIGHT)
			{
				player.isMovingHorizontally = false;
			}
		}

		if (receivedSignals[InputSignal.LEFT_PRESS])
		{
			if (player.direction != Direction.LEFT)
			{
				player.direction = Direction.LEFT;
			}
			player.isMovingHorizontally = true;
		}
		if (receivedSignals[InputSignal.LEFT_RELEASE])
		{
			if (player.direction == Direction.LEFT)
			{
				player.isMovingHorizontally = false;
			}
		}

		if (receivedSignals[InputSignal.JUMP_PRESS])
		{
			player.startJump(3);
		}

		if (receivedSignals[InputSignal.USE_PRESS])
		{
			player.prepareToPickOrDrop;
		}
	}

	void unregisterAllSignals()
	{
		for (size_t signalId = 0; signalId < receivedSignals.length; signalId++)
		{
			receivedSignals[signalId] = false;
		}
	}

public:
    this(string fileName, size_t rendererWidth=120, size_t rendererHeight=45,
		 IUserInterface ui=null)
    {
		_ui = ui;

		// If length of the longest line in the file is shorter than provided
		// renderer width, then renderer width is shrinked to the length of the
		// longest line in the file.
		const size_t maxLineLength = getMaxLineLength(fileName);
		if (maxLineLength < rendererWidth)
		{
			rendererWidth = maxLineLength;
		}

		// Create renderer
		_renderer = new Renderer(rendererWidth, rendererHeight);

		// Create first area
		areas ~= new Area(this, _renderer.pixelGrid[0].length);

		// Create player and pass its reference to Area
		player = new LivingObject(areas[0], 1, 0, Direction.RIGHT, 1);
		player.addPixel('\U0000003e', 0, 0, Direction.RIGHT);    // >
		player.addPixel('\U0000003c', 0, 0, Direction.LEFT);     // <
		player.recalculateProperties;
		areas[0].player = player;

		// Parse provided file + create game objects based on that parsing
		parse(this, fileName, rendererWidth, rendererHeight, 7);

		// Mark first and last Areas in the list
		areas[0].isFirst = true;
		areas[$ - 1].isLast = true;
		activeAreaId = 0;

		// Display total number of areas on UI
		if (_ui !is null)
		{
			_ui.displayAreasTotal(areas.length);
		}
    }

	/**
	Toggle signal state to true in the receivedSignals array
	*/
	void registerSignal(InputSignal inputSignal)
	{
		receivedSignals[inputSignal] = true;
	}

	/**
	Update states of all logical objects contained by the Game
	*/
    void update()
    {
		handleInput;
		areas[activeAreaId].updateObjects;
		unregisterAllSignals;
    }

	/**
	Generate and return dstring representation of the current Area of the Game
	*/
	dstring renderDstring()
	{
        _renderer.clear;
		areas[activeAreaId].renderAllObjects;
		return _renderer.toAsciiDstring;
	}

	/**
	Generate and return string representation of the current Area of the Game
	*/
	string renderString()
	{
        _renderer.clear;
		areas[activeAreaId].renderAllObjects;
		return _renderer.toAsciiString;
	}

	//-------------------//
	// Interface methods //
	//-------------------//

	/**
	Switch game to next Area, keeping player's x coordinate
	*/
	override void switchToNextArea()
	{
		activeAreaId++;
		player.area = areas[activeAreaId];
		player.setPosition(player.getX, 0, false);
		if (_ui !is null)
		{
			_ui.displayCurrentAreaNumber(activeAreaId + 1);
		}
	}

	/**
	Create new Area, append it to the list of Areas and make it active
	*/
	override void createNextActiveArea()
	{
		areas ~= new Area(this, player, _renderer.pixelGrid[0].length);
		activeAreaId++;
	}

	/**
	Return reference to the currently active Area
	*/
	override @property IObjectContainer activeArea()
	{
		return areas[activeAreaId];
	}

	/**
	Return reference to Pixel grid container
	*/
	override @property IPixelGridContainer renderer()
	{
		return _renderer;
	}

	/**
	Return the amount of collected coins for the current game
	*/
	override @property uint coinsCollected()
	{
		return _coinsCollected;
	}

	/**
	Set the amount of collected coins for the current game
	*/
	override @property void coinsCollected(uint value)
	{
		_coinsCollected = value;
		if (_ui !is null)
		{
			_ui.displayCoins(value);
		}
	}
}