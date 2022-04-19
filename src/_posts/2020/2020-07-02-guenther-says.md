---
author: christian
title: "Günther says: Eine CSS Übung"
locale: de
ref: guenther-says
tags: ['javascript', 'html', 'projects', 'css']
image: /assets/guenther-says.png
---

Es fing mit einer kleinen CSS Übung an und ist dann ein bisschen
eskaliert. "[Günther says][guenther]" ist ein "Simon says" Klon welcher
komplett in JavaScript und HTML/CSS programmiert ist.

[guenther]: https://guenther.serverless.industries/

![Günther says]({{'/assets/guenther-says.png' | relative_url}}){:.img-fluid}

"Günther says" kann hier gespielt werden: [https://guenther.serverless.industries/][guenther]

## Kreise

Kreise lassen sich ganz einfach aus einem `<div>` erzeugen:

```css
.circle {
    width: 100px;
    height: 100px;
    border: 4px solid black;
    border-radius: 100%;
    background-color: red;
}
```

```html
<div class="circle"></div>
```

<div style="clear: both; margin: 20px 0px; display: block;">
    <div style="width:100px; height: 100px; border: 4px solid black; background-color: red; border-radius: 100%;"></div>
</div>

## Invertierte Runde Kanten

Invertiert lassen sich runde Kanten nicht so einfach realisieren.
Hier müssten zwei `<div>` Container ineinander verschachtelt werden.

```css
.circle {
    width: 100px;
    height: 100px;
    overflow:hidden;
    position: relative;
    border-top-left-radius: 100%;
    background-color: green;
}

.circle .edge {
    width: 100px;
    height: 100px;
    position: absolute;
    background-color: white;
    border-radius: 100%;
    bottom: -50%;
    right: -50%;
}
```

```html
<div class="circle">
    <div class="edge"></div>
</div>
```

<div style="clear: both; margin: 20px 0px; display: block;">
    <div style="width: 100px; height: 100px; overflow:hidden; position: relative; border-top-left-radius: 100%; background-color: green;">
        <div style="width: 100px; height: 100px; position: absolute; background-color: white; border-radius: 100%; bottom: -50%; right: -50%;"></div>
    </div>
</div>

Quelle: [https://stackoverflow.com/a/22422105](https://stackoverflow.com/a/22422105)

## Skalieren mit dem Browser Fenster

[flex]: https://css-tricks.com/snippets/css/a-guide-to-flexbox/
[borderbox]: https://developer.mozilla.org/en-US/docs/Web/CSS/box-sizing
[vu]: https://css-tricks.com/fun-viewport-units/

Dank so wunderbarer Techniken wie [Flexbox][flex], [Viewport Units][vu]
und [box-sizing][borderbox] ist die einzige Herausforderung, dem
äußersten Container die korrekte `width` und `height` zuzuweisen.
Alle weiteren Elemente können anschließend Prozentwerte nutzen.

```css
.square {
    width: 20vh;
    height: 20vh;
    border: 4px solid black;
    background-color: red;
    box-sizing: border-box;
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
}

.window {
    width: 60%;
    height: 60%;
    background-color: blue;
    border-radius: 50% 50% 10% 10%;
}
```

```html
<div class="square">
    <div class="window"></div>
</div>
```

<div style="clear: both; margin: 20px 0px; display: block;">
    <div style="width: 20vh; height: 20vh; border: 4px solid black; background-color: red; box-sizing: border-box; display: flex; flex-direction: row; justify-content: center; align-items: center;">
        <div style="width: 60%; height: 60%; background-color: blue; border-radius: 50% 50% 10% 10%;"></div>
    </div>
</div>

Die Größe dieses Beispiels sollte sich ändern, wenn das Browserfenster in der
Höhe vergrößert oder verkleinert wird.
