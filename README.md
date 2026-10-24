# Ralph Lorence Racho — Portfolio

A static, dependency-free portfolio site. Plain HTML5, CSS3 and vanilla JavaScript —
no framework, no npm packages, no build step.

```
ralph-portfolio/
├─ index.html
├─ styles.css
├─ script.js
└─ assets/
   ├─ ralph.png              ← profile photo (already in place)
   ├─ ralph-racho-cv.pdf     ← ADD THIS: the CV file
   └─ projects/              ← screenshots + preview clips for the three projects
```

## The CV

`assets/ralph-racho-cv.pdf` is generated, one page, A4, all text in black, with
the portrait from `assets/ralph.png` embedded at the top of the right-hand
column (the script crops it to 4:5 and re-encodes it as a JPEG image object, so
swapping `ralph.png` and re-running is all it takes). To change the wording,
edit the CONTENT block in `cv/build-cv.ps1` and run:

```powershell
powershell -File cv\build-cv.ps1
```

The script writes the PDF directly (headless Chrome/Edge printing is blocked in
some environments), so it needs nothing installed. `cv/cv.html` is the same CV
as a web page — handy for previewing wording, and printable from the browser
with Ctrl+P if you prefer that output.

## Before publishing

Check the two details I had to infer, in `index.html`, `cv/cv.html` and
`cv/build-cv.ps1`: the school (**Cebu Eastern College**) and the program
(**BS Information Technology**). Correct them if either is wrong.

Contact details are live: `ralphracho123@gmail.com`,
[github.com/ralphracho123](https://github.com/ralphracho123) and
[facebook.com/ralph.racho.7](https://www.facebook.com/ralph.racho.7).

## Run it locally

Open `index.html` in a browser, or serve the folder:

```bash
python -m http.server 5500
```

A local server is worth it for the CV viewer — browsers restrict embedded PDFs
on `file://`.

## Deploy to Vercel

No configuration needed — it's a plain static folder.

```bash
npm i -g vercel
vercel          # from inside ralph-portfolio/
```

Or push the folder to GitHub and import the repo at vercel.com. When asked for a
framework preset choose **Other**, leave the build command empty, and set the
output directory to the project root.

## Theme

Light and dark, toggled in the header. The first visit follows the operating
system setting; after that the choice is remembered in `localStorage`. The theme
is applied by a small inline script in `<head>`, so there is no flash of the
wrong one on load.

## Motion

Hero lines mask up on load, the lede highlights draw in, sections and cards
reveal on scroll, the stat figures count up, the timeline accent bars grow, a
progress bar tracks the scroll, and the project screenshots cross-fade into
short preview clips once a card is on screen (wide viewports only — phones keep
the still image, so nothing heavy downloads on mobile data). All of it is
disabled under `prefers-reduced-motion: reduce`.

## Responsiveness

Laid out fluidly with CSS Grid, Flexbox, `clamp()` and `min()`, with breakpoints
that re-arrange (not just shrink) at 1024px, 900px (nav switches to the mobile
panel), 860px, 720px, 480px and 360px, plus a short-landscape rule for phones
held sideways. Checked at 320 / 375 / 430 / 768 / 1024 / 1280 / 1440px.

## Accessibility notes

- Skip link, visible focus rings, semantic landmarks and headings.
- Mobile menu: `aria-expanded`, Escape to close, focus kept in the panel, focus
  returned to the button, closes on link tap and on resize past the breakpoint.
- No information is hover-only, so touch devices lose nothing.
- `prefers-reduced-motion` disables the reveal animations and the marquee.
