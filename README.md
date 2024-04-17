<h6 align="center">nowaaru presents...</h6>
<h3 align="center">power 💥 mode</h3>

<hr />
<p align="center">
  <h6 align="center">
    <img src="https://github.com/Nowaaru/power-mode.nvim/assets/16274568/91f6d776-3928-4547-ab4e-175627bf0cd5" />    
    <br />
    <a href="https://github.com/Nowaaru/power-mode.nvim/blob/ce685cc27b232fe4e8cf6f8b05ec2ba654710e17/src/lua/power-mode/init.lua#L64C1-L91C4"> 
      How do I get something like this?
    </a>
  </h6>
</p>
<hr />
<h3>What the heck is this?! Why the heck is this?!</h3>
<p>
  Power Mode is a concept originally imaged by the wise <a href="https://github.com/joelbesada">@JoelBesada</a>
  for the <a href="http://codeinthedark.com/">Code in the Dark</a> competition. Glorious particles would fill
  the screen, highlighting your unmatched intellect as the characters flow from your fingers. A glowing counter
  would scroll upwards endlessly, marking your every milestone with a fighting game-esque compliment. 

  At least, that's how I remembered it.
  
  Once I swapped from Visual Studio Code, I craved that satisfaction the more I burnt out. WakaTime could only do so
  much, and I have even less in cash to give them, so I had to use my secret weapon: <b>Attention Deficit Hyperactivity Disorder</b>.
  <h6>Description</h6>
  Activate 2 of these effects. <b>Must</b> be done at the same time.
  <br/> 
  <br/>
  <ul>
    <li>
      Target 1 face-up <b>Bug</b>-like monster your opponent controls.
      <br/>
      Send that monster to the graveyard. If this action is chosen and 
      this card is brought back into play, any damage dealt by this monster 
      will do 1.5x damage due to immense confusion and anger. All forms of damage 
      will target this monster.
    </li>
    <li>
      Remove up to two <b>Burnout</b> cards from your field. Two turns after,
      if a <b>Bug</b>-like monster has not been sent to the graveyard, add
      four <b>Burnout</b> cards to the field.
    </li>
    <li>
      Remove up to four <b>Bug</b>-like cards from the field. Every turn,
      one <b>Feature Creep</b> card is added to the field. Every three turns,
      the opponent may place down a <b>Bug</b>-like card from their <b>deck</b>.
    </li>
  </ul>

  You can probably guess which two I chose. Instead of having the same-old-same-old
  "everyone-has-the-same-design," why not instead provide the resources to make their
  <b>own</b> custom design and supply semi-customizable presets for those too lazy (which I completely understand)?

  <!-- TODO: Remove this after implementing particles (if it's not impossible). -->
  As of writing, there aren't any particles. However, there <i>is</i> <a href="https://github.com/Nowaaru/power-mode.nvim/blob/ce685cc27b232fe4e8cf6f8b05ec2ba654710e17/src/lua/power-mode/init.lua#L64C1-L91C4">an example</a>
  that shows how to get started with using some of the bars. The library is fairly well-documented, so I shouldn't need to touch on that very much here.
</p>
<hr />
<h3>Getting Started: Presets</h3>
Hello, fellow approval-deprived traveler!
To first get started with presets, you'll have to require it.

<!-- TODO: Update when more presets are available. -->
As of writing, there is only one preset: the <b>Boss</b> preset.
This preset is shown at the top of the README page.

It consists of a stacked health bar, a percentage, and a randomized
name that can be modified through the fields. This class is well-documented.

To use a preset, require the file and create 
a new object from the constructor. The default 
group name is a field of the `power-mode` module. 

```lua
local PowerMode = require("power-mode");
local BossFactory = require("power-mode.presets.boss");

local Boss = BossFactory.new(PowerMode.__group_name);
```

Afterwards, run your `init` function to have
preset do all the internal hooking-up for you.

When that's done, you'll need to have some kind
of loop to make the good-ol' guy tick:

```lua
local PowerMode = require("power-mode");
local BossFactory = require("power-mode.presets.boss");

local Boss = BossFactory.new(PowerMode.__group_name);

vim.api.vim_set_decoration_provider(PowerMode.__namespace, {
  on_start = function(...)
    return Boss:tick()
  end
});
```

<h3>Getting Started: Manual</h3>
Hello, fellow happiness-deprived traveler!
I really wouldn't advise this without a good
pair of headphones or IEMs.

With that said, the first thing we have to
get through is the setup. First and foremost,
require all of your modules!

```lua
local MyPreset = {};
local Scorekeep = require("power-mode.scorekeep");
local PowerWindow = require("power-mode.power-window");
local PowerLayer = require("power-mode.power-layer");
```

A brief description of these modules:
<ul>
  <li>
    Scorekeep
    <ul>
      <li>
        Keeps track of every individual score across many buffers.
        <br/>
      </li>
    </ul>
  </li>
  <li>
    PowerWindow
    <ul>
      <li>
        The PowerWindow module is responsible for everything related to the floating window<br/>
        system. Without it, nothing shows.
        <br/>
        <br/>
        In short, it gets your doohickeys going.
      </li>
    </ul>
  </li>
  <li>
    PowerLayer
    <ul>
      <li>
        The PowerLayer module is responsible for displaying your beautiful pixelated graphics<br/>
        onto the window.
        <br/>
        <br/>
        When all is done, bind it to the window, and woah! Technology! 📺 🌈
      </li>
    </ul>
  </li>
</ul>

Due to my being a Roblox developer at heart, we'll be using an object-oriented
approach for this. It's nice to promote customizability without affecting other
instances.

```lua
local Scorekeep = require("power-mode.scorekeep");
local PowerWindow = require("power-mode.power-window");
local PowerLayer = require("power-mode.power-layer");

local Preset = {};
Preset.__prototype = {};
Preset.__index = Preset.__prototype;

function Preset.new(namespace)
  local Object = {};

  return setmetatable(Object, Preset);
end
```

All preset objects **must** have a tick class.
To accentuate this, we will make missing prototype
methods fallback to an erroneous function.

```lua
function Preset.__prototype:tick()
  error("This function is not implemented.");
end

function Preset.__prototype:on_start()
  error("This function is not implemented.");
end

function Preset.__prototype:init()
  error("This function is not implemented.");
end

function Preset.__prototype:deinit()
  error("This function is not implemented.");
end
```

You should **always** create the window in the `init` method. Anywhere else
and you sacrifice end-user control for (usually) no real reason.

To get started with making your window, you should primarily keep in mind
that everything in this library is a class. Oh, and also that data belonging 
to the object stays *inside* the object. Thus, we construct a new PowerWindow
class and store the reference inside of the new Object. 

Oh, and let's customize it a little bit! Why not?

```lua
local PowerWindow = require("power-mode.power-window");
local AnchorType = require("power-mode.power-window.anchortype"); -- 🌟

[...]

function Preset.new(namespace)
  local self = setmetatable({}, Preset);

  function self:init()
    self.window = PowerWindow.new();
    self.window:SetAnchorType(AnchorType.CURSOR);
    self.window:BindToNamespace(namespace);

    self.window.Width = "8%";
    self.window.Height = 2;

    self.window:Show();
  end

  return self;
end
```

<h6><i>Hweh?!</i> What is this <b>HERESY?</b> I'm setting what's <b><i>SUPPOSED</i></b> to be an integer
to a string?</h6>
In this library, spatial fields can be set to integer percentage values similarly to CSS.
<br/>
<br/>
It's now time to add some bells and whistles to our window! Let's just have a simple
bar with a background:

```lua
local PowerWindow = require("power-mode.power-window");
local PowerLayer = require("power-mode.power-layer");
local AnchorType = require("power-mode.power-window.anchortype");
local unpack = unpack or table.unpack; -- 🌟


[...]

function Preset.new(namespace)
  local self = setmetatable({}, Preset);

  function self:init()
    self.window = PowerWindow.new();
    self.window:SetAnchorType(AnchorType.CURSOR);
    self.window:BindToNamespace(namespace);

    self.window.Width = "8%";
    self.window.Height = 2;

    self.window.Y = -self.window.Height - 1; -- Offset one more cell because of a potential outline.

    local background = PowerLayer.new("Background", namespace, self.window.__buf);
    local bar = PowerLayer.new("Bar", namespace, self.window.__buf);

    background:Background("#DF2935");
    bar:Bar(0, 0, 0.5, "#FFFFFF");

    self.window:AddLayer(background, bar);
    self.window:Show();
  end

  return self;
end
```

We have our window! However, it won't show if you don't
<b>render the window and its components.</b> Yes, that's
right. You even have to do this yourself.<br/>
<h6>I hope your music is going great!</h6>
So, let's set a timer for our renderer so we don't crush
our NeoVim's performance by using a decoration provider.
If you believe it won't, either you're wrong or your computer
is just that much better than mine.

```lua
function Preset.new(namespace)
  local self = setmetatable({}, Preset);
  local timer = vim.loop.new_timer();
  

  function self:init()
    self.window = PowerWindow.new();
    self.window:SetAnchorType(AnchorType.CURSOR);
    self.window:BindToNamespace(namespace);

    self.window.Width = "8%";
    self.window.Height = 2;

    self.window.Y = -self.window.Height - 1; -- Offset one more cell because of a potential outline.

    local background = PowerLayer.new("Background", namespace, self.window.__buf);
    local bar = PowerLayer.new("Bar", namespace, self.window.__buf);

    background:Background("#DF2935");
    bar:Bar(0, 0, 0.5, "#FFFFFF");

    self.window:AddLayer(background, bar);
    self.window:Show();

    timer:start(0, 100, function()
      vim.schedule(function()
        self.window:AddLayer(background, bar);
        self.window:RenderWindow();
        self.window:RenderComponents();
      end)
    end)
  end

  return self;
end
```

It is highly important to call `vim.schedule` when
dealing with anything related to updating the UI
in Power Mode - even if it's something as simple as
score calculation. Updating windows and buffers
inside a timer does not mix well with Vim.<br/>
<br/>
It's not very free to call AddLayer so flippantly as
layers are not a dictionary but an array that is 
iterated over. Sometime later down the line I'll
get making layers a dictionary where the values
contain the order instead of the keys.<br/>
<br/>
With that out of the way, we have a functional Preset!
All that's needed to get this preset running is a hook-up
to a decoration provider and all is well.<br/>
<br/>
But what if we wanted to get this bar *moving?* It's not
too hard, surprisingly enough. All that needs to be done
is to use some upvalues and move the layer painting into
the renderer. Oh, and to hook up the Scorekeeper. <br/>
<br/>
<b>Be sure to clear the layer first, otherwise
artifacts may appear!</b>
<!--TODO: this! ^^ -->

```lua
function Preset.new(namespace)
  local self = setmetatable({}, Preset);
  local timer = vim.loop.new_timer();

  local background, bar;
  function self:init()
    self.window = PowerWindow.new();
    self.window:SetAnchorType(AnchorType.CURSOR);
    self.window:BindToNamespace(namespace);

    self.window.Width = "8%";
    self.window.Height = 2;

    self.window.Y = -self.window.Height - 1; -- Offset one more cell because of a potential outline.

    background = PowerLayer.new("Background", namespace, self.window.__buf);
    bar = PowerLayer.new("Bar", namespace, self.window.__buf);

    self.window:AddLayer(background, bar);
    self.window:Show();

    timer:start(0, 100, function()
      vim.schedule(function()
        background:Clear();
        bar:Clear();

        background:Background("#DF2935");
        bar:Bar(0, 0, 0.5, "#FFFFFF");

        self.window:AddLayer(background, bar);
        self.window:RenderWindow();
        self.window:RenderComponents();
      end)
    end)
  end

  return self;
end
```

Now to get that scorekeeper up and running. It's fairly
simple, make a new scorekeeper instance that's bound
to a group name and use the `Ensure` method with
no arguments to guarantee that the current buffer
is being tracked.<br/>
<br/>
Then, call the `ScoreHandler` method with the
returned `ScoreEntry` item as the argument. This
method modifies the ScoreEntry itself, so no need
to worry about calling `Ensure` again.<br/>
<br/>
I'll be lazy here by tostring-ing the namespace
for the group.

```lua
function Preset.new(namespace)
  local self = setmetatable({}, Preset);
  local timer = vim.loop.new_timer();
  local scorekeeper = Scorekeep.new(tostring(namespace)); -- 🌟

  local background, bar;
  function self:init()
    self.window = PowerWindow.new();
    self.window:SetAnchorType(AnchorType.CURSOR);
    self.window:BindToNamespace(namespace);

    self.window.Width = "8%";
    self.window.Height = 2;

    self.window.Y = -self.window.Height - 1; -- Offset one more cell because of a potential outline.

    background = PowerLayer.new("Background", namespace, self.window.__buf);
    bar = PowerLayer.new("Bar", namespace, self.window.__buf);

    self.window:AddLayer(background, bar);
    self.window:Show();

    timer:start(0, 100, function()
      vim.schedule(function()
        local scoreEntry = scorekeeper:Ensure(); -- 🌟
        background:Clear();
        bar:Clear();

        background:Background("#DF2935");
        bar:Bar(0, 0, scoreEntry.score / scorekeeper.scoreCap --[[ 🌟 ]], "#FFFFFF");

        self.window:AddLayer(background, bar);
        self.window:RenderWindow();
        self.window:RenderComponents();
      end)
    end)
  end

  return self;
end
```

And that's it! There's your functional preset, made from scratch!
You totally, most definitely did not copy-paste this! If you did,
that's okay - it's probably because you know what you're doing.
<br/>
<br/>
Go ahead and hook that `tick()` function to a decoration provider
and watch your world go wild!
And just like that, your preset is ready to go!
Most presets are very customizable and allow you
unparalleled freedom. Good luck!
