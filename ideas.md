# Ideas

## Idea "ganadora?"

Raymarch version:

```glsl
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    int x = int(uv.x * 320.) - 160;
    int y = int(uv.y * 240.);
    int idx;
    const vec3 palette[] = vec3[](
     vec3(0., 0., 0.),
     vec3( 0./63., 28./63., 28./63.), // l0
     vec3( 0./63., 42./63., 42./63.), // l1
     vec3( 0./63., 63./63., 63./63.), // l0+l1
     vec3(42./63., 0./63.,   0./63.), // l2
     vec3(32./63., 32./63., 32./63.), // l0+l2
     vec3(40./63., 40./63., 40./63.), // l1+l2
     vec3(45./63., 63./63., 63./63.), // l0+l1+l2     
     vec3(28./63., 0./63.,  63./63.), // l3  
     vec3(31./63., 31./63., 63./63.), // l0+l3
     vec3(31./63., 39./63., 63./63.), // l1+l3
     vec3(31./63., 63./63., 63./63.), // l0+l1+l3
     vec3(63./63.,  0./63., 31./63.), // l2+l3
     vec3(63./63., 31./63., 63./63.), // l0+l2+l3
     vec3(63./63., 45./63., 63./63.), // l1+l2+l3
     vec3(63./63., 63./63., 63./63.) // l1+l2+l3+l4
    );
    
    vec3 col;
    int d = 16;
    int bitmap[] = int[](        
        0x8e, 0xa6, 0xa0,
        0xc8, 0xee, 0xe0,
        0xe8, 0xec, 0xa0
    );

    int x1 = (-2*iFrame % 1024) - 640;
    int x2 = x;
    idx = 0;
    int row = y / 16;
    if (row >= 6 && row < 9) {
        for (int i = 0; i < 4; i++) {
            int ofx = x2 - x1;
            if (ofx > 0) {
              int pos = (ofx / 16) / 8;
              int bit = (ofx / 16) % 8;
              if (pos < 3 && ((0x80>>bit) & bitmap[3*(row-6)+pos]) != 0) {
                idx += (8 >> i);
              }
            }
            x2 += x/8;
        }      
    }

    // Output to screen
    fragColor = vec4(palette[idx],1.0);
}
```

```glsl
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    const float prlx[] = float[](1., 0.9062, 0.81095, 0.7175);
    int x = int(uv.x * 320.) - 160;
    int y = int(uv.y * 240.);
    int idx;
    const vec3 palette[] = vec3[](
     vec3(0., 0., 0.),
     vec3( 0./63., 28./63., 28./63.), // l0
     vec3( 0./63., 42./63., 42./63.), // l1
     vec3( 0./63., 63./63., 63./63.), // l0+l1
     vec3(42./63., 0./63.,   0./63.), // l2
     vec3(32./63., 32./63., 32./63.), // l0+l2
     vec3(40./63., 40./63., 40./63.), // l1+l2
     vec3(45./63., 63./63., 63./63.), // l0+l1+l2     
     vec3(28./63., 0./63.,  63./63.), // l3  
     vec3(31./63., 31./63., 63./63.), // l0+l3
     vec3(31./63., 39./63., 63./63.), // l1+l3
     vec3(31./63., 63./63., 63./63.), // l0+l1+l3
     vec3(63./63.,  0./63., 31./63.), // l2+l3
     vec3(63./63., 31./63., 63./63.), // l0+l2+l3
     vec3(63./63., 45./63., 63./63.), // l1+l2+l3
     vec3(63./63., 63./63., 63./63.) // l1+l2+l3+l4
    );
    
    vec3 col;
    int d = 32;

    int x1 = (-2*iFrame % 320) - 160;
    
    idx = 0;
    if (abs(y-120)<100) {
    
        if (abs(x-x1) < d) {
          idx += 8;
        }
        
        if (abs(100*x/105 - x1) < d) {
          idx += 4;
        }

        if (abs(100*x/115 - x1) < d) {
          idx += 2;
        }

        if (abs(100*x/130 - x1) < d) {
          idx += 1;
        }
        
    }

    // Output to screen
    fragColor = vec4(palette[idx],1.0);
}

```

Para debugear:
https://yjdoc2.github.io/8086-emulator-web/compile


## Idea 1: 2D pattern

- https://www.shadertoy.com/view/mtyGWy - The shader toy code for a nice example of a 2D shader
- [An introduction to Shader Art Coding](https://www.youtube.com/watch?v=f4s1h2YETNY) -  A video explaining how it was done


## Idea 2: Lens effect

I want to simulate a collimated ray of white light that hits a lens and add spacial and color aberration caused by the small angle approximation and the index of refraction dependence on wavelength.


## Idea 3: make 3D version of our mod n planes

The idea is to take Hellmood's 'Into a new era' but use our pattern and possibly add some color to it

- [Into a new era](https://www.pouet.net/prod.php?which=78044) - Pouet entry
- [Shader toy version](https://www.shadertoy.com/view/4tVBzD)

## Idea 4: My bitfield with zoom

- [Shader toy version](https://www.shadertoy.com/view/3flfzf) - My bitfields animation


## Idea 5: Apple 2 demo

Several years ago I wrote some super tiny ~60 byte intros for the Apple 2. I want to maybe convert them to text and add some simple variation.

- [A text demo I did for the Apple II BASIC Bot](https://cesarmiquel.github.io/art/tech/2021/07/12/week-28.html) - No longer available but I have the code
- [The Apple II demos](https://cesarmiquel.github.io/tech/2020/05/04/week-19.html)
- [A YouTube video of them](https://www.youtube.com/watch?v=zJpT-gt-ZO4)
- This nice demo I did in Basic


```BASIC
10 HOME:A$=" .:'!|!':. ":X=1:VTAB14:HTAB14:?"W . A . V . E"
20 VTAB12:HTAB15:FORY=1TO11:?MID$(A$,X,1);:X=X+1:IFX>10THENX=1
30 NEXTY:GOTO20
```


## Idea 6: Try to recreate a scene from WarGames


In the movie the tension of is broken when Joshoa stops the war simulation and the computer voice says "Hello, professor Falcon". Try to recreate as much of it in JS using text 2 speach

- [The snipet from the Movie](https://www.youtube.com/watch?v=v11Y64dnnF4&t=9s)
- The complete dialogue:

Joshua: Greetings, professor Falcon
Professor Falcon: Hello
Joshua: A strange game. The only winning move is not to play. How about a nice game of chess?


```Javascript
let u = new SpeechSynthesisUtterance("Greet-ings, pro-fessor Falcon. . . . . Strange game. The, only, winning, move is, not to, play");
u.rate = .8;  // Slightly faster speed (range: 0.1 to 10)
u.pitch = 0.3; // Low pitch (range: 0 to 2)
speechSynthesis.speak(u);

let u = new SpeechSynthesisUtterance("Greetingsss professor Falcon");
u.pitch = 0.2; // Low pitch (range: 0 to 2)
u.rate = 0.8;  // Slightly faster speed (range: 0.1 to 10)
speechSynthesis.speak(u);

// Sync text to sound
function speakAndSync() {
const container = document.getElementById('text-container');
const originalText = container.innerText;

// Create the utterance
const utterance = new SpeechSynthesisUtterance(originalText);
utterance.pitch = 0.2; // Keep your robotic pitch
utterance.rate = 1.0;

// The magic happens here: fires at every word boundary
utterance.onboundary = function(event) {
    if (event.name === 'word') {
        const charIndex = event.charIndex;
        
        // Find the length of the word currently being spoken
        const remainingText = originalText.substring(charIndex);
        const wordMatch = remainingText.match(/^[\w']+/); 
        const wordLength = wordMatch ? wordMatch[0].length : 0;

        // Reconstruct the HTML with a span wrapping the active word
        const before = originalText.substring(0, charIndex);
        const activeWord = originalText.substring(charIndex, charIndex + wordLength);
        const after = originalText.substring(charIndex + wordLength);

        container.innerHTML = `${before}<span class="highlight">${activeWord}</span>${after}`;
    }
};

// Reset text styling when finished
utterance.onend = function() {
    container.innerHTML = originalText;
};

// Cancel any ongoing speech and speak
speechSynthesis.cancel();
speechSynthesis.speak(utterance);
```

## Idea 7: Linux terminal animation

Love these spinners: https://x.com/orhundev/status/2101333307279433915

## Idea 8: recreate these images


https://x.com/RikOostenbroek/status/2097717088693481770


## Idea 9: transparent / glass shaders/raymarchers

- [Raymarching explanation by Claude](https://claude.ai/share/c065a4b7-0cbd-4e31-88f0-2bc9dd2118bc) - I asked for an explanation of a beautiful raymarched image that looked like glass: https://x.com/Jaenam97/status/2092970419716247594
- [Twitter account](https://x.com/Jaenam97)
- [Spectral Donut](https://x.com/Jaenam97/status/2098418240900804947) - [GrafCoords.xyz version](https://fragcoord.xyz/s/s9becmzu)

## Idea X: Do an effect similiar to the ReMPDed demo scroll

- https://youtu.be/gKUF5pLJSW0?si=izTLG5xQRjoeHhhP&t=126
- Code here: `~/Develop/Demos/MSDOS/remoded_final/SOURCES/SCENES/SCROLL`
- Code here to generate PPM: `~/Develop/Demos/256b/digimind-disintegration`

## References


- [Marquee design writeups](https://marqueedesign.demoscene.com/blog/index.html) - Their blog with writeups for some of their demos
- [Gaia writeup](https://marqueedesign.demoscene.com/blog/blog_gaia.html) - READ
- [The Perspective and Orthographic Projection Matrix](https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/building-basic-perspective-projection-matrix.html)

