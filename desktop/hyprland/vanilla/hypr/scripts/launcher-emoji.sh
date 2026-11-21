#!/usr/bin/env bash
# ==============================================================================
# Hyprland Emoji Picker Launcher
# Modern Wayland emoji selector with Wofi / hyprlauncher / rofi fallbacks,
# clipboard integration (wl-copy / xclip / python GTK), and wtype direct typing.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/launcher-guard.sh" ]]; then
    source "$SCRIPT_DIR/launcher-guard.sh"
    guard_launcher "emoji"
fi

# ------------------------------------------------------------------------------
# Comprehensive Global Emoji Dataset (Smileys, Gestures, Nature, Food, Tech, Symbols)
# ------------------------------------------------------------------------------
EMOJI_LIST="$(cat << 'EOF'
😀 grinning face happy smile
😃 smiling face with big eyes happy
😄 smiling face with smiling eyes laugh
😁 beaming face with smiling eyes grin
😆 grinning squinting face laugh haha
😅 grinning face with sweat nervous relief
🤣 rolling on the floor laughing rofl lol
😂 face with tears of joy cry laugh lol
🙂 slightly smiling face pleasant
🙃 upside-down face sarcasm ironic
😉 winking face wink flirt
😊 smiling face with smiling eyes blush happy
😇 smiling face with halo innocent angel
🥰 smiling face with hearts in love adore
😍 smiling face with heart-eyes love adore
🤩 star-struck excited amazed wow
😘 face blowing a kiss love kiss
😗 kissing face kiss
😚 kissing face with closed eyes kiss
😋 face savoring food delicious yum tasty
😛 face with tongue silly joke
😜 winking face with tongue playful crazy
🤪 zany face goofy wild wacky
😝 squinting face with tongue playful funny
🤑 money-mouth face rich cash dollar
🤗 smiling face with open hands hug welcome
🤭 face with hand over mouth oops giggle
🤫 shushing face quiet secret hush
🤔 thinking face hmm consider wonder
🤐 zipper-mouth face secret silent shut
🤨 face with raised eyebrow skeptical suspect
😐 neutral face blank expressionless meh
😑 expressionless face unamused blank
😶 face without mouth silent quiet mute
😏 smirking face smirk sly smug
😒 unamused face annoyed bored displeased
🙄 face with rolling eyes eye roll whatever
😬 grimacing face awkward nervous yikes
🤥 lying face pinocchio liar
😌 relieved face phew calm peace
😔 pensive face sad thoughtful sorrow
😪 sleepy face tired droop
🤤 drooling face drool yum hungry
😴 sleeping face zzz sleep snore
😷 face with medical mask sick doctor virus
🤒 face with thermometer sick fever illness
🤕 face with head-bandage hurt injured head
🤢 nauseated face sick disgust gross vomit
🤮 face vomiting puking sick barf
🤧 sneezing face sneeze sick allergy
🥵 hot face heat sweat boiling summer
🥶 cold face freezing ice winter frost
🥴 woozy face drunk tipsy dizzy uneven
😵 dizzy face passed out disoriented
🤯 exploding head mind blown shock amaze
🤠 cowboy hat face western yeehaw
🥳 partying face celebrate party horn hat
😎 smiling face with sunglasses cool awesome badass
🤓 nerd face geek glasses smart
🧐 face with monocle classy inspect investigate
😕 slightly frowning face unsure puzzled
😟 worried face nervous anxious
🙁 frowning face unhappy sad
😮 face with open mouth surprised shocked wow
😯 hushed face stunned surprise
😲 astonished face shocked amaze
😳 flushed face embarrassed blush shock
🥺 pleading face please puppy eyes beg
😦 frowning face with open mouth worry
😧 anguished face distress pain
😨 fearful face scared afraid terror
😰 anxious face with sweat worried nervous
😥 sad but relieved face phew sweat
😢 crying face tear sad weep
😭 loudly crying face sob crying tears bawl
😱 face screaming in fear shocked scream horror
😖 confounded face frustrated struggle
😣 persevering face struggling endure
😞 disappointed face sad regret
😓 downcast face with sweat stressed phew
😩 weary face exhausted tired
😫 tired face frustrated give up
🥱 yawning face sleepy bored yawn
😤 face with steam from nose angry proud fume
😡 enraging face angry mad pouting red
😠 angry face annoyed mad grouchy
🤬 face with symbols on mouth cursing swear anger
😈 smiling face with horns devil evil mischievous
👿 angry face with horns imp devil sinister
💀 skull dead rip skeleton death
☠️ skull and crossbones danger pirate poison
💩 pile of poo poop crap stool
🤡 clown face circus goofy
👻 ghost boo spooky halloween spirit
👽 alien extraterrestrial ufo space
👾 alien monster 8bit video game arcade
🤖 robot bot android mechanical
🎃 jack-o-lantern pumpkin halloween lantern
😺 grinning cat feline happy
😸 grinning cat with smiling eyes feline
😹 cat with tears of joy feline laugh
😻 smiling cat with heart-eyes feline love
😼 cat with wry smile feline smirk
😽 kissing cat feline kiss
🙀 weary cat feline shocked scream
😿 crying cat feline tear sad
😾 pouting cat feline angry grumpy

👋 waving hand hello goodbye wave
🤚 raised back of hand stop
🖐️ hand with fingers splayed five palm
✋ raised hand stop high five palm
🖖 vulcan salute spock live long prosper
👌 OK hand perfect okay correct fine
🤌 pinched fingers italian chef kiss what
🤏 pinching hand tiny little bit small
✌️ victory hand peace two v sign
🤞 crossed fingers luck hope wish
🤟 love-you gesture ily rock
🤘 sign of the horns rock on metal heavy
🤙 call me hand shaka hang loose surf
👈 backhand index pointing left point west
👉 backhand index pointing right point east
👆 backhand index pointing up point north
🖕 middle finger offensive vulgar rude
👇 backhand index pointing down point south
☝️ index pointing up one attention first
👍 thumbs up good like approve yes great
👎 thumbs down bad dislike disapprove no fail
✊ raised fist power solidarity punch
👊 oncoming fist punch fist bump combat
🤛 left-facing fist punch bump
🤜 right-facing fist punch bump
👏 clapping hands applause bravo clap praise
🙌 raising hands hooray celebrate praise amen
👐 open hands hug welcome jazz hands
🤲 palms up together pray offer hope
🤝 handshake deal agreement partnership agree
🙏 folded hands please pray thanks namaste gratitude
✍️ writing hand write author note pen
💅 nail polish manicure beauty polish salon
🤳 selfie phone camera photography
💪 flexed biceps muscle strong power fitness
🦾 mechanical arm cyborg prosthetic bionic
🦿 mechanical leg cyborg prosthetic bionic
🦵 leg limb thigh foot
🦶 foot feet toe step kick
👂 ear hear listen sound audio
🦻 ear with hearing aid accessibility
👃 nose smell sniff scent
🧠 brain smart think mind intelligence
🫀 anatomical heart organ cardiology
🫁 lungs breath respiration organ
🦷 tooth teeth dental dentist molar
🦴 bone skeleton dog calcium
👀 eyes look see watch gaze vision
👁️ eye vision watch observer monitor
👅 tongue taste lick mouth saliva
👄 mouth lips kiss lipstick smile

❤️ red heart love affection passion
🧡 orange heart love warm care
💛 yellow heart love friend sunshine
💚 green heart love nature envy
💙 blue heart love loyalty calm
💜 purple heart love royalty magic
🖤 black heart dark gothic sorrow
🤍 white heart pure clean peace
🤎 brown heart love chocolate earthy
💔 broken heart heartbreak sorrow dump
❤️‍🔥 heart on fire burning passion flame
❤️‍🩹 mending heart healing recovery better
❣️ heart exclamation love punctuation
💕 two hearts love floating romance
💞 revolving hearts affection moving love
💓 beating heart heartbeat vibration love
💗 growing heart excited pulse expansion
💖 sparkling heart love shiny sparkle
💘 heart with arrow cupid romance love
💝 heart with ribbon gift Valentine box
💟 heart decoration purple emblem

🐶 dog face puppy pet canine bark
🐱 cat face kitten pet feline meow
🐭 mouse face rodent cheese squeak
🐹 hamster face rodent pet wheel
🐰 rabbit face bunny pet carrot
🦊 fox face sly red wild vulpine
🐻 bear face teddy grizzly brown
🐼 panda face bamboo china bear
🐨 koala face australia eucalyptus marsupial
🐯 tiger face wild stripes predator
🦁 lion face king jungle roar mane
🐮 cow face farm moo dairy cattle
🐷 pig face oink farm pork snout
🐸 frog face amphibian toad ribbit green
🐵 monkey face primate macaque ape
🐔 chicken face hen farm poultry cluck
🐧 penguin face bird antarctica cold waddle
🐦 bird tweet fly feather wing
🐤 baby chick cute bird yellow hatch
🦆 duck quack bird waterfowl mallard
🦅 eagle bird america raptor majestic
🦉 owl wise bird night hoot nocturnal
🦇 bat nocturnal spooky vampire cave
🐺 wolf howl wild lupine pack
🐗 boar wild pig tusks forest
🐴 horse face equine pony gallop
🦄 unicorn magical fantasy horse horn
🐝 honeybee bee bug honey pollen sting
🐛 bug caterpillar insect larva green
🦋 butterfly pretty insect wings cocoon
🐌 snail slow shell mollusk crawl
🐞 lady beetle ladybug bug spots red
🐜 ant insect colony worker hill
🦟 mosquito bug insect bite malaria
🦗 cricket bug insect chirp grasshopper
🕷️ spider arachnid web eight legs
🕸️ spider web cobweb silk trap
🦂 scorpion desert arachnid sting claws
🐢 turtle tortoise slow reptile shell
🐍 snake reptile serpent venom slither
🦎 lizard reptile gecko chameleon tail
🦖 T-Rex dinosaur tyrannosaurus jurassic dino
🦕 sauropod dinosaur brontosaurus dino
🐙 octopus sea marine tentacle kraken
🦑 squid calamari sea cephalopod ink
🦐 shrimp prawn seafood crustacean
🦞 lobster seafood crustacean claws
🦀 crab crustacean sea claws pinch
🐡 blowfish pufferfish fish swell spike
🐠 tropical fish aquarium coral nemo
🐟 fish seafood swim fin aquatic
🐬 dolphin ocean marine swim mammal
🐳 spouting whale ocean sea giant mammal
🐋 whale ocean mammal leviathan marine
🦈 shark predator ocean jaws fins teeth
🦭 seal ocean sea pinniped mammal
🐊 crocodile alligator reptile river swamp
🐅 tiger predator stripes jungle feline
🐆 leopard cheetah wild spotted speed
🦓 zebra safari stripes african savanna
🦍 gorilla ape primate silverback jungle
🦧 orangutan primate ape borneo sumatra
🦣 mammoth prehistoric elephant tusks ice
🐘 elephant trunk safari tusks africa india
🦛 hippo hippopotamus safari water river
🦏 rhinoceros rhino safari horn armor
🐪 camel desert hump dromedary arid
🐫 two-hump camel desert bactrian arid
🦒 giraffe safari tall neck spots savanna
🦘 kangaroo australia joey pouch hop
🦬 bison buffalo wild plains herd
🐃 water buffalo cattle horn domestic
🐂 ox bull cattle beef farm strong
🐄 cow cattle dairy milk farm steer
🐎 horse stallion gallop race equestrian
🐖 pig sow pork farm animal
🐏 ram sheep horn meadow wool
🐑 ewe sheep wool lamb meadow
🦙 llama alpaca wool andes fleece
🐐 goat farm billy kid horns
🦌 deer buck antlers forest wildlife
🐕 dog canine pet faithful friend
🐩 poodle dog curly fancy canine
🦮 guide dog service blind assistance
🐕‍🦺 service dog vest helper support
🐈 cat feline pet whiskers domestic
🐈‍⬛ black cat feline spooky witch superstition
🐓 rooster cock farm poultry dawn crow
🦃 turkey bird thanksgiving gobble poultry
🦤 dodo extinct bird mauritius rare
🦚 peacock bird feather display proud
🦜 parrot bird talk tropical feathers
🦩 flamingo bird pink wading lake
🕊️ dove peace bird white olive branch
🐇 rabbit bunny pet burrow meadow
🦝 raccoon bandit trash panda nocturnal
🦨 skunk stink smelly stripe scent
🦡 badger fierce burrow animal
🦦 otter cute river sea aquatic play
🦥 sloth slow tree lazy canopy
🐁 mouse rodent tiny gray squeak
🐀 rat rodent sewer whiskers rodent
🐿️ chipmunk squirrel acorn nut rodent
🦔 hedgehog spines cute mammal prickle
🐾 paw prints animal tracks foot trail
🐉 dragon mythical fantasy reptile fire
🐲 dragon face mythical beast scales
🌵 cactus desert plant succulent spines
🎄 Christmas tree holiday pine decoration
🌲 evergreen tree pine forest fir conifer
🌳 deciduous tree nature forest leaf wood
🌴 palm tree beach tropical oasis island
🌱 seedling plant sprout growth new baby
🌿 herb plant green leaf mint seasoning
☘️ shamrock clover ireland saint patrick
🍀 four leaf clover lucky luck fortune charm
🎍 pine decoration bamboo japanese kadomatsu
🪴 potted plant houseplant greenery flora
🎋 tanabata tree bamboo paper festival wish
🍃 leaf fluttering in wind foliage autumn
🍂 fallen leaf autumn foliage dry brown
🍁 maple leaf autumn canada fall season
🍄 mushroom fungus toadstool spore forest
🌾 sheaf of rice grain wheat agriculture crop
💐 bouquet flowers gift love romance floral
🌷 tulip spring flower bulb blossom petal
🌹 rose red flower love romance beauty
🥀 wilted flower dead rose sorrow fading
🌺 hibiscus tropical flower aloha summer
🌸 cherry blossom sakura flower spring japan
🌼 blossom yellow flower petal daisy
🌻 sunflower yellow sun flower summer seeds
🌞 sun with face sunny bright warm morning
🌝 full moon with face night bright lunar
🌛 first quarter moon with face smiling
🌜 last quarter moon with face dream
🌚 new moon with face dark eclipse lunar
🌕 full moon night bright glow lunar
🌖 waning gibbous moon phase
🌗 last quarter moon half
🌘 waning crescent moon thin
🌑 new moon night dark space sky
🌒 waxing crescent moon sky
🌓 first quarter moon half phase
🌔 waxing gibbous moon bright
🌙 crescent moon night ramadan sleep dream
🪐 ringed planet saturn space astronomy orbit
💫 dizzy star sparkle orbit swirl
⭐ star favorite rating astronomy yellow
🌟 glowing star sparkle shiny bright gold
✨ sparkles stars clean magic shiny glitter
⚡ high voltage zap electricity lightning bolt shock
☄️ comet space asteroid meteor ice trail
💥 collision boom explode bang crash burst
🔥 fire flame lit hot burn blaze campfire
🌪️ tornado storm wind vortex twister cyclone
🌈 rainbow colorful sky pride spectrum
☀️ sun sunny warm weather daylight solar
🌤️ sun behind small cloud sky weather
⛅ sun behind cloud weather overcast partly
🌥️ sun behind large cloud cloudy day
☁️ cloud cloudy overcast sky weather vapor
🌦️ sun behind rain cloud sunshower rain
🌧️ cloud with rain rainy storm shower weather
⛈️ cloud with lightning and rain thunder storm
🌩️ cloud with lightning storm thunder bolt
🌨️ cloud with snow snowy winter cold flake
❄️ snowflake snow cold winter frost crystal
☃️ snowman with snow winter frost cold
⛄ snowman winter cold hat scarf snow
🌬️ wind face breeze blowing breath blow
💨 dashing away fast smoke puff rush speed
💧 droplet water sweat tear aqua liquid
💦 sweat droplets splash water spray sweat
🫧 bubbles soap water lather foam floating
☂️ umbrella rain weather cover protection
☔ umbrella with rain drops wet storm shower
🌊 water wave ocean sea surf tsunami crest

🍏 green apple fruit granny smith tart
🍎 red apple fruit sweet orchard cider
🍐 pear fruit sweet bosc anjou
🍊 tangerine orange citrus fruit clementine
🍋 lemon citrus sour yellow lemonade
🍌 banana fruit potassium peel yellow
🍉 watermelon fruit summer melon slice seeds
🍇 grapes fruit wine purple vineyard bunch
🍓 strawberry fruit berry red shortcake
🫐 blueberries fruit berry blue healthy pancake
🍈 melon cantaloupe honeydew sweet fruit
🍒 cherries fruit cherry pair sweet sundae
🍑 peach fruit juicy fuzzy orchard
🥭 mango fruit tropical sweet stone fruit
🍍 pineapple fruit tropical ananas hawaii
🥥 coconut tropical nutty fruit palm milk
🥝 kiwi fruit green brown fuzzy tart
🍅 tomato red fruit vegetable vine marinara
🍆 eggplant aubergine vegetable purple ratatouille
🥑 avocado guacamole fruit healthy toast
🥦 broccoli green vegetable healthy florets
🥬 leafy green salad lettuce vegetable greens
🥒 cucumber pickle green vegetable salad crunch
🌶️ hot pepper chili spicy red jalapeno heat
🫑 bell pepper capsicum vegetable sweet crisp
🌽 ear of corn maize sweetcorn grain cob
🥕 carrot orange vegetable beta root crunchy
🫒 olive oil martini green savory tapas
🧄 garlic clove seasoning cook aroma vampire
🧅 onion vegetable slice cook tear savory
🥔 potato spud fries tuber mash bake
🍠 roasted sweet potato yam autumn snack
🥐 croissant pastry french bakery flaky butter
🥯 bagel bread bakery cream cheese breakfast
🍞 bread loaf bakery sliced toast grain
🥖 baguette bread french bakery crisp loaf
🥨 pretzel salted snack bakery knot bavarian
🧀 cheese wedge dairy swiss cheddar gouda
🥚 egg chicken breakfast protein shell yolk
🍳 cooking egg fried breakfast skillet sunnyside
🧈 butter dairy spread cook baking spread
🥞 pancakes flapjacks breakfast syrup stack
🧇 waffle breakfast grid batter syrup belgian
🥓 bacon pork strips breakfast meat crispy rashers
🥩 cut of meat steak beef raw butcher sirloin
🍗 poultry leg chicken drumstick meat roasted
🍖 meat on bone cartoon roast shank feast
🌭 hot dog frankfurter sausage mustard bun
🍔 hamburger burger fastfood beef patty cheese
🍟 french fries chips fastfood potato snack
🍕 pizza slice cheese pepperoni italian pie
🫓 flatbread naan pita roti bread unleavened
🥪 sandwich lunch deli bread sub blt
🥙 stuffed flatbread gyro pita falafel shawarma
🧆 falafel chickpea middle eastern vegan fritter
🌮 taco mexican tortilla shell carnitas salsa
🌯 burrito mexican wrap tortilla beans rice
🫔 tamale mexican husk masa steamed lard
🥗 green salad healthy bowl greens caesar vinaigrette
🥘 shallow pan of food paella curry skillet
🫕 fondue melted cheese pot alpine dip
🥫 canned food tin soup beans pantry preserve
🍝 spaghetti pasta italian noodle tomato bolognese
🍜 steaming bowl ramen noodle soup broth noodles
🍲 pot of food stew soup hotpot hearty
🍛 curry rice indian japanese spicy sauce
🍣 sushi nigiri raw fish japanese wasabi
🍱 bento box japanese lunch meal tray
🥟 dumpling gyoza potsticker dim sum wrapper
🦪 oyster seafood pearl shell mignonette raw
🍤 fried shrimp tempura seafood crunchy prawn
🍙 rice ball onigiri nori japanese snack
🍚 cooked rice bowl white rice jasmine basmati
🍘 rice cracker senbei japanese savory soy
🍥 fish cake with swirl narutomaki ramen topper
🥠 fortune cookie chinese lucky message crispy
🥮 mooncake mid-autumn pastry chinese lotus
🍢 oden skewer japanese street food dashi
🍡 dango skewer sweet mochi japanese festival
🍧 shaved ice snow cone dessert sweet kakigori
🍨 ice cream scoop bowl dessert sweet gelato
🍦 soft ice cream cone dessert sweet swirl
🥧 pie pastry baked dessert slice apple pecan
🧁 cupcake frosting muffin baked dessert icing
🍰 shortcake strawberry cake dessert slice sponge
🎂 birthday cake celebration anniversary candle
🍮 custard pudding flan caramel dessert creme
🍭 lollipop candy sweet sucker candy stick
🍬 candy sweet treat confection wrapped bonbon
🍫 chocolate bar candy sweet cocoa dark milk
🍿 popcorn movie snack theater butter salted
🍩 doughnut donut pastry sweet glaze fried ring
🍪 cookie chocolate chip baked sweet biscuit
🌰 chestnut nut autumn roasted acorn
🥜 peanuts nut snack shell legume butter
🍯 honey pot sweet bee nectar drizzle gold
🥛 glass of milk dairy drink beverage calcium
🍼 baby bottle milk drink formula infant
🫖 teapot tea brew kettle hot porcelain
☕ hot beverage coffee tea mug cafe espresso
🍵 teacup without handle green tea matcha sencha
🧃 beverage box juice drink straw apple orange
🥤 cup with straw soda drink softdrink beverage
🧋 bubble tea boba milk tea tapioca pearl
🫗 pouring liquid spill splash drink drip
🍶 sake bottle cup japanese alcohol rice wine
🍺 beer mug pint brew alcohol lager ale
🍻 clinking beer mugs cheers toast pint celebration
🥂 clinking glasses champagne toast celebration fizz
🍷 wine glass red wine alcohol vineyard vintage
🍸 cocktail glass martini olive alcohol classy
🍹 tropical drink umbrella cocktail rum tiki
🧉 mate tea gourd straw argentine caffeine
🍾 bottle with popping cork champagne celebration bubbly
🧊 ice cube cold freeze chill water rock

💻 laptop computer macbook pc tech notebook coding
🖥️ desktop computer pc mac screen monitor imac
🖨️ printer print office paper tech scanner laser
⌨️ keyboard typing computer tech mechanical qwerty
🖱️ computer mouse click scroll peripheral optical
💽 computer disk minidisc optical md retro
💾 floppy disk save vintage 3.5 storage diskette
💿 optical disk cd dvd disc media compact
📀 dvd digital video disc movie optical storage
🧮 abacus math counting vintage calculate bead
🎥 movie camera cinema film recording cam
🎞️ film frames cinema movie negative reel
📽️ film projector movie cinema display screen
🎬 clapper board movie film cinema director scene
📺 television tv screen broadcast display monitor
📷 camera photo photography picture snapshot lens
📸 camera with flash photo picture snapshot capture
📹 video camera camcorder record tape movie
📼 videocassette vhs retro tape movie recorder
🔍 magnifying glass tilted left search zoom find query
🔎 magnifying glass tilted right search zoom find query
🕯️ candle flame wax light wick aroma glow
💡 light bulb idea innovation energy lamp bright invent
🔦 flashlight torch light beam dark battery night
🏮 red paper lantern izakaya asian festival chochin
🪔 diya oil lamp diwali hindu festival wick clay
📔 notebook with decorative cover journal diary book
📕 closed book red hardcover reading library novel
📖 open book reading novel study literature pages
📗 green book reading novel study library
📘 blue book reading novel study manual
📙 orange book reading novel study textbook
📚 books stack library reading study school education
📓 notebook spiral journal notes study composition
📒 ledger yellow lined journal binder account
📃 page with curl paper document script memo
📜 scroll parchment ancient document diploma roll
📄 page facing up paper document sheet article
📰 newspaper news article press journal headline
🗞️ rolled-up newspaper delivery media morning
📑 page marker tabs flags bookmark index organize
🔖 bookmark ribbon page reader save reference
🏷️ label tag price identifier name sticker
💰 money bag cash rich wealthy dollar riches
🪙 coin currency money gold silver metal cent
💴 yen banknote japanese money currency cash
💵 dollar banknote usd cash currency money buck
💶 euro banknote european currency money cash
💷 pound banknote british sterling currency cash
💸 money with wings loss cash spending transfer fly
💳 credit card payment visa debit plastic purchase
🧾 receipt bill expense invoice payment proof
✉️ envelope mail letter postal message paper
📧 e-mail electronic mail message inbox digital
📨 incoming envelope mail letter inbox receive
📩 envelope with arrow send mail received dispatch
📦 package parcel delivery box cardboard shipping
📫 closed mailbox with raised flag mail post letter
📬 open mailbox with raised flag new mail post
✏️ pencil write draw sketch lead graphite eraser
✒️ black nib pen fountain calligraphy ink
🖋️ fountain pen write ink signature luxury
🖊️ pen ballpoint write document signature office
🖌️ paintbrush art painting artist stroke canvas
🖍️ crayon color draw sketch wax coloring kids
📝 memo notepad note write reminder pencil
💼 briefcase luggage business work leather office
📁 file folder documents organizing directory folder
📂 open file folder documents directory files folder
🗂️ card index dividers catalog organization tabs
📅 calendar date schedule event day month year
📆 tear-off calendar schedule date day reminder
🗒️ spiral notepad notes memo pad paper list
🗓️ spiral calendar schedule planner event organizer
📈 chart increasing up trend growth profit analytics
📉 chart decreasing down loss drop trend decline
📊 bar chart analytics stats graph data column
📋 clipboard notes checklist tasks paste copy board
📌 pushpin thumb tack map location pin notice
📍 round pushpin map pin location marker place
📎 paperclip attach clip document office wire
📏 straight ruler measure inches centimeters distance
📐 triangular ruler architect math geometry triangle
✂️ scissors cut shear paper craft tool blade
🗑️ wastebasket trash can garbage bin delete remove
🔒 locked secure safety closed privacy lock encrypt
🔓 unlocked open safety security privacy unlock
🔐 locked with key security privacy protect lock
🔑 key password access unlock door login security
🗝️ old key vintage skeleton lock access secret
🔨 hammer tool construct build hardware nail strike
🪓 axe chop wood hatchet lumberjack blade
⛏️ pickaxe mine ore quarry dig mining tool
🛠️ hammer and wrench tools repair maintenance service
⚔️ crossed swords combat battle fight duel weapon
💣 bomb explosive blast tnt hazard weapon ignite
🏹 bow and arrow archery target hunter weapon
🛡️ shield protect defense armor security barrier
🔧 wrench spanner tool repair mechanical bolt nut
🪛 screwdriver tool fix screw tighten flathead phillips
🔩 nut and bolt hardware screw thread fastener
⚙️ gear cog settings mechanical machinery engine
⚖️ balance scale justice law court measure equity
🔗 link hyperlink chain connected url web internet
🧰 toolbox tools repair hardware kit chest
🧲 magnet attraction physics magnetic force horseshoe
🧪 test tube science chemistry experiment glass lab
🧬 dna genetics science biology helix code genome
🔬 microscope science lab biology zoom lens scientific
🔭 telescope astronomy space stars galaxy view lens
📡 satellite antenna dish signal wireless comms broadcast
💉 syringe needle medical injection vaccine shot
💊 pill capsule medication pharmacy tablet dose medicine
🩹 adhesive bandage bandaid wound healing firstaid
🩺 stethoscope doctor medical nurse heartbeat listen
🚪 door entrance exit portal handle entryway
🪟 window view glass transparent frame hyprland
🛏️ bed sleep mattress hotel rest bedroom
🛋️ couch and lamp sofa living room furniture lounge
🪑 chair seat furniture sit stool armchair
🚽 toilet restroom bathroom flush porcelain wc
🪠 plunger plumbing clog repair suction suction
🚿 shower wash bathe bathroom clean hygiene water
🛁 bathtub soak bath relaxation lather hygiene
🪒 razor shave grooming barber sharp blade clean
🧴 lotion bottle sunscreen moisturizer skin cosmetic
🧷 safety pin diaper needle secure fastener
🧹 broom sweep clean dust witch chore tidy
🧺 basket laundry wicker weave storage hamper
🧻 roll of paper toilet paper tissue wipe bathroom
🪣 bucket pail water cleaning mop wash
🧼 soap bar clean bubbles wash hygiene lather
🪥 toothbrush dental hygiene clean teeth paste brush
🧽 sponge wash clean scrub absorbent wipe dish
🧯 fire extinguisher emergency safety fire flame protect
🛒 shopping cart grocery retail market buy purchase

🚗 automobile car red vehicle drive road motor
🚕 taxi cab yellow vehicle fare drive uber
🚙 sport utility vehicle suv car auto 4x4
🚌 bus transit transport passenger vehicle school
🚎 trolleybus electric transit bus wire
🏎️ racing car race f1 motorsport vehicle track
🚓 police car cop emergency siren vehicle patrol
🚑 ambulance emergency hospital paramedic medic call
🚒 fire engine emergency truck fire rescue ladder
🚐 minibus van passenger transit vehicle camper
🛻 pickup truck utility flatbed haul cargo truck
🚚 delivery truck cargo shipping transport lorry
🚛 articulated lorry semi trailer freight truck logistics
🚜 tractor farm agriculture harvest vehicle plow
🚲 bicycle bike cycle ride pedal gear commute
🛵 motor scooter moped vespa bike scooter
🏍️ motorcycle motorbike speed chopper engine
🚨 police car light flashing siren emergency red blue
🚀 rocket spaceship launch space nasa blastoff journey
🛸 flying saucer ufo alien extraterrestrial sci-fi
🚁 helicopter chopper aviation flight air rescue
✈️ airplane flight aviation aircraft travel plane jet
🛫 airplane departure takeoff airport travel fly
🛬 airplane arrival landing airport travel runway
🪂 parachute skydive airborne leap drop freefall
🛰️ satellite orbit space communications gps dish
🚢 ship cruise boat vessel ocean voyage nautical
🛳️ passenger ship cruise liner ocean luxury vacation
🚤 speedboat racing boat ocean water motorboat
⛵ sailboat yacht ocean water wind sail boat
⚓ anchor marine boat sailor naval port harbor
⛽ fuel pump gas station petrol refill energy diesel
🗺️ world map navigation geography globe atlas
🧭 compass direction navigation north orientation explore
🏔️ snow-capped mountain peak climb alps summit
⛰️ mountain peak nature hike landscape scenic
🌋 volcano eruption lava magma crater ash mountain
🏕️ camping tent campfire outdoors wilderness hike
🏖️ beach with umbrella resort coast vacation summer
🏝️ desert island tropical paradise isolated palm
🏟️ stadium arena sports concert event crowd
🏛️ classical building bank museum courthouse columns hall
🏗️ building construction crane development site work
🏠 house home building residential dwelling shelter
🏡 house with garden home suburban lawn yard
🏢 office building skyscraper workplace business tower
🏥 hospital medical clinic doctor healthcare emergency
🏦 bank finance money deposits loan institution cash
🏨 hotel accommodation lodging travel luxury motel
🏫 school education classroom study building university
🏬 department store retail shopping mall building shop
🏭 factory industrial manufacturing plant pollution chimney
🏰 castle fantasy kingdom fortress medieval palace
🗼 tokyo tower landmark red communication japan landmark
🗽 statue of liberty new york landmark freedom usa

✅ check mark button verified done ok tick success agree
✔️ check mark tick done correct passed verified right
☑️ check box with check ballot vote selected checked
❌ cross mark cancel delete wrong failed error reject no
❎ cross mark button cancel reject error x box
➕ plus sign add sum positive increase bonus
➖ minus sign subtract negative decrease remove
➗ division sign divide math calculation divide
✖️ multiplication sign multiply times cancel product
🟰 heavy equals sign math equal same equivalent
💯 hundred points 100 perfect score top best percent
🚫 prohibited forbidden ban restricted no denied
❗ red exclamation mark warning alert important notice
❕ white exclamation mark note alert info bang
❓ red question mark help inquiry query faq doubt
❔ white question mark help query ask unknown
‼️ double exclamation mark warning alert alarm priority
⁉️ exclamation question mark surprise shock query what
⚠️ warning alert caution hazard danger sign yield
⛔ no entry forbidden stop road sign access deny
🛑 stop sign halt road traffic danger octagon red
🔴 red circle dot record indicator crimson sphere
🟢 green circle dot active online success ok emerald
🔵 blue circle dot indicator info azure sky
🟡 yellow circle dot caution warning gold amber
🟣 purple circle dot indicator violet plum
⚫ black circle dot dark off dark pitch
⚪ white circle dot empty light silver
🟥 red square block stop ruby
🟩 green square block go jade
🟦 blue square block lapis
🟨 yellow square block caution amber
🟪 purple square block amethyst
⬛ black large square block ebony
⬜ white large square block ivory
🔺 red triangle pointed up increase rise top
🔻 red triangle pointed down decrease drop bottom
🏁 checkered flag finish race winner chequered victory
🚩 triangular flag post mark priority notice red flag
🏴 black flag pirate anarchy dark banner
🏳️ white flag surrender peace truce clean banner
🏳️‍🌈 rainbow flag pride lgbtq identity freedom equal
🏳️‍⚧️ transgender flag trans identity pride trans
🏴‍☠️ pirate flag skull jolly roger crossbones buccaneer
♾️ infinity endless forever loop eternal limitless
♻️ recycling symbol eco green earth recycle sustainable
💲 heavy dollar sign money cash currency price
©️ copyright legal registered mark all rights reserved
®️ registered trademark legal intellectual property
™️ trade mark branding legal logo mark
💬 speech balloon message chat comment say text talk
💭 thought balloon think dream imagine ponder cloud
💤 zzz sleeping tired zzz snore sleep
🎵 musical note melody song audio tune sound
🎶 musical notes music melody song audio notes
🔊 speaker high volume loud sound audio blast sound
🔇 muted speaker silent quiet audio off mute silence
📢 loudspeaker announcement bullhorn public shout alert
🔔 bell notification alert chime ring alarm bell
🔕 bell with slash mute silent notifications off silent
🎯 bullseye target goal hit direct focus accurate
🎮 video game controller gaming joystick console play
🕹️ joystick arcade gaming retro controller retro
🎲 game die dice roll luck casino boardgame random
🎉 party popper confetti celebration congrats woo yay
🎊 confetti ball celebrate congratulations party ball
🎁 wrapped gift present birthday holiday ribbon surprise
🎈 balloon party floating celebration helium red
🏆 trophy champion winner 1st gold award first
🥇 1st place medal first gold champion winner victory
🥈 2nd place medal second silver runner-up second
🥉 3rd place medal third bronze award third
EOF
)"

selection=""

# ------------------------------------------------------------------------------
# 1. Native hyprlauncher dmenu mode
# ------------------------------------------------------------------------------
if command -v hyprlauncher >/dev/null 2>&1; then
    raw_sel="$(printf '%s\n' "$EMOJI_LIST" | hyprlauncher -m 2>/dev/null || true)"
    if [[ -n "$raw_sel" && "$raw_sel" != "Exited without selection" ]]; then
        selection="$raw_sel"
    fi
fi

# ------------------------------------------------------------------------------
# 2. Modern Wayland dmenu mode (Wofi)
# ------------------------------------------------------------------------------
if [[ -z "$selection" ]] && command -v wofi >/dev/null 2>&1; then
    wofi_conf=""
    wofi_style=""

    for c in "$HOME/.config/wofi/config" \
             "$SCRIPT_DIR/../../wofi/config"; do
        if [[ -f "$c" ]]; then
            wofi_conf="$c"
            break
        fi
    done

    for s in "$HOME/.config/wofi/style.css" \
             "$SCRIPT_DIR/../../wofi/style.css"; do
        if [[ -f "$s" ]]; then
            wofi_style="$s"
            break
        fi
    done

    # Proportionate 8-column grid layout for Wofi
    WOFI_ARGS=(
        "--dmenu"
        "-p" "Search emoji..."
        "--columns" "8"
        "--lines" "8"
        "--width" "760"
        "--matching" "fuzzy"
        "--insensitive"
        "--hide-scroll"
    )
    [[ -n "$wofi_conf" ]] && WOFI_ARGS+=(--conf "$wofi_conf")
    [[ -n "$wofi_style" ]] && WOFI_ARGS+=(--style "$wofi_style")

    raw_sel="$(printf '%s\n' "$EMOJI_LIST" | wofi "${WOFI_ARGS[@]}" 2>/dev/null || true)"
    if [[ -n "$raw_sel" ]]; then
        selection="$raw_sel"
    fi
fi

# ------------------------------------------------------------------------------
# 3. Fallback: Rofi emoji / dmenu mode (8-column grid)
# ------------------------------------------------------------------------------
if [[ -z "$selection" ]] && command -v rofi >/dev/null 2>&1; then
    if [[ -z "${ROFI_CONFIG:-}" ]]; then
        if [[ -f "$HOME/.config/rofi/config.rasi" ]]; then
            export ROFI_CONFIG="$HOME/.config/rofi/config.rasi"
        elif [[ -f "$SCRIPT_DIR/../../rofi/config.rasi" ]]; then
            export ROFI_CONFIG="$(cd "$SCRIPT_DIR/../../rofi" && pwd)/config.rasi"
        fi
    fi

    ROFI_THEME_STR='window { width: 760px; } listview { columns: 8; lines: 8; spacing: 6px; } element { orientation: vertical; padding: 6px; } element-text { horizontal-align: 0.5; }'
    if [[ -x "$HOME/.config/hypr/scripts/rofi-menu.sh" ]]; then
        raw_sel="$(printf '%s\n' "$EMOJI_LIST" | "$HOME/.config/hypr/scripts/rofi-menu.sh" dmenu "Emoji" -theme-str "$ROFI_THEME_STR" -matching fuzzy 2>/dev/null || true)"
    else
        raw_sel="$(printf '%s\n' "$EMOJI_LIST" | rofi -dmenu -p "Emoji" -theme-str "$ROFI_THEME_STR" -matching fuzzy 2>/dev/null || true)"
    fi

    if [[ -n "$raw_sel" ]]; then
        selection="$raw_sel"
    fi
fi

# Dismissed or canceled
[[ -z "$selection" ]] && exit 0

# Extract emoji glyph (first whitespace-separated token)
emoji="${selection%% *}"
[[ -z "$emoji" ]] && exit 0

# ------------------------------------------------------------------------------
# Clipboard Dispatch (wl-copy / xclip / python GTK fallback)
# ------------------------------------------------------------------------------
if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$emoji" | wl-copy
fi
if command -v xclip >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    printf '%s' "$emoji" | xclip -selection clipboard 2>/dev/null || true
fi
if ! command -v wl-copy >/dev/null 2>&1 && ! command -v xclip >/dev/null 2>&1 && [[ -f "$SCRIPT_DIR/clipboard-copy.py" ]]; then
    printf '%s' "$emoji" | python3 "$SCRIPT_DIR/clipboard-copy.py" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# Direct Window Typing Dispatch (wtype / ydotool fallback)
# ------------------------------------------------------------------------------
if command -v wtype >/dev/null 2>&1; then
    # Brief pause to allow window manager focus to return to the active application window
    sleep 0.1
    wtype "$emoji" 2>/dev/null || true
elif command -v ydotool >/dev/null 2>&1; then
    sleep 0.1
    ydotool type "$emoji" 2>/dev/null || true
fi

# Notification confirmation
if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "Emoji Picker" "Emoji Copied" "$emoji copied to clipboard" -t 1500 2>/dev/null || true
fi
