# Sticky Footer, Five Ways

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://css-tricks.com/couple-takes-sticky-footer/>
> 对应题目：CSS 第 15 题 · Sticky Footer
> 抓取时间：2026-09-22

---

[flexbox](<https://css-tricks.com/tag/flexbox/>) [footer](<https://css-tricks.com/tag/footer/>) [grid](<https://css-tricks.com/tag/grid/>) [sticky footer](<https://css-tricks.com/tag/sticky-footer/>)

#  Sticky Footer, Five Ways 

![](https://secure.gravatar.com/avatar/41a6f9778d12dfedcc7ec3727d64a12491d75d9a65d4b9323feb075391ae6795?s=80&d=retro&r=pg)

[ Chris Coyier ](<https://css-tricks.com/author/chriscoyier/>) on  May 25, 2016 

The purpose of a sticky footer is that it “sticks” to the bottom of the browser window. But not always, if there is enough content on the page to push the footer lower, it still does that. But if the content on the page is short, a sticky footer will still hang to the bottom of the browser window.

Note that “sticky” here is exactly as described above. It’s not to be confused with `position: fixed;` which can be used to “stick” an element in place even if the page scrolls. Or, even more confusingly, it’s not `position: sticky;` either, which is liked fixed positioning inside of containers sort of.

![](https://css-tricks.com/wp-content/uploads/2016/05/sticky-footer-1.svg)

### [](<https://css-tricks.com/couple-takes-sticky-footer/#there-is-negative-bottom-margins-on-wrappers>)There is negative bottom margins on wrappers

There was a wrapping element that held everything except the footer. It had a negative margin equal to the height of the footer. That was the basis of [this one](<http://ryanfait.com/html5-sticky-footer/>). 

    <body>
      <div class="wrapper">

          content

        <div class="push"></div>
      </div>
      <footer class="footer"></footer>
    </body>

    html, body {
      height: 100%;
      margin: 0;
    }
    .wrapper {
      min-height: 100%;

      /* Equal to height of footer */
      /* But also accounting for potential margin-bottom of last child */
      margin-bottom: -50px;
    }
    .footer,
    .push {
      height: 50px;
    }

See the Pen [Sticky Footer with calc();](<http://codepen.io/chriscoyier/pen/VjZmGj/>) by Chris Coyier ([@chriscoyier](<http://codepen.io/chriscoyier>)) on [CodePen](<http://codepen.io>).

This one required an extra element inside the content area (the “`.push`“), to ensure that the negative margin didn’t pull the footer up and cover any content. The push was also clever because it very likely didn’t have any bottom margin of it’s own. If it did, that would have to be factored into the negative margins, and having those two numbers not in sync doesn’t look quite as nice.

### [](<https://css-tricks.com/couple-takes-sticky-footer/#there-is-negative-top-margins-on-footers>)There is negative top margins on footers

[This](<http://www.cssstickyfooter.com/>) technique did not require a push element, but instead, required an extra wrapping element around the content in which to apply matching bottom padding to. Again to prevent negative margin from lifting the footer above any content.

    <body>
      <div class="content">
        <div class="content-inside">
          content
        </div>
      </div>
      <footer class="footer"></footer>
    </body>

    html, body {
      height: 100%;
      margin: 0;
    }
    .content {
      min-height: 100%;
    }
    .content-inside {
      padding: 20px;
      padding-bottom: 50px;
    }
    .footer {
      height: 50px;
      margin-top: -50px;
    }

See the Pen [Sticky Footer with Negative Margins 2](<http://codepen.io/chriscoyier/pen/aZoBMb/>) by Chris Coyier ([@chriscoyier](<http://codepen.io/chriscoyier>)) on [CodePen](<http://codepen.io>).

Kind of a wash between this technique and the previous one, as they both require extra otherwise unnecessary HTML elements. 

### [](<https://css-tricks.com/couple-takes-sticky-footer/#there-is-calc-reduced-height-wrappers>)There is calc() reduced height wrappers

[One way](<https://priteshgupta.com/2016/05/sticky-css-footer/>) to not need any extra elements is to adjust the wrappers height with calc(). Then there is not any overlapping going on, just two elements stacked on top of each other totaling 100% height.

    <body>
      <div class="content">
        content
      </div>
      <footer class="footer"></footer>
    </body>

    .content {
      min-height: calc(100vh - 70px);
    }
    .footer {
      height: 50px;
    }

See the Pen [Sticky Footer with calc();](<http://codepen.io/chriscoyier/pen/jqRXBz/>) by Chris Coyier ([@chriscoyier](<http://codepen.io/chriscoyier>)) on [CodePen](<http://codepen.io>).

Notice the 70px in the calc() vs. the 50px fixed height of the footer. That’s making an assumption. An assumption that the last item in the content has a bottom margin of 20px. It’s that bottom margin plus the height of the footer that need to be added together to subtract from the viewport height. And yeah, we’re using viewport units here as another little trick to avoid having to set 100% body height before you can set 100% wrapper height.

### [](<https://css-tricks.com/couple-takes-sticky-footer/#there-is-flexbox>)There is flexbox

The big problem with the above three techniques is that they require fixed height footers. Fixed heights are generally a bummer in web design. Content can change. Things are flexible. Fixed heights are usually red flag territory. [Using flexbox for a sticky footer](<https://philipwalton.github.io/solved-by-flexbox/demos/sticky-footer/>) not only doesn’t require any extra elements, but allows for a variable height footer.

    <body>
      <div class="content">
        content
      </div>
      <footer class="footer"></footer>
    </body>

    html, body {
      height: 100%;
    }
    body {
      display: flex;
      flex-direction: column;
    }
    .content {
      flex: 1 0 auto;
    }
    .footer {
      flex-shrink: 0;
    }

See the Pen [Sticky Footer with Flexbox](<http://codepen.io/chriscoyier/pen/RRbKrL/>) by Chris Coyier ([@chriscoyier](<http://codepen.io/chriscoyier>)) on [CodePen](<http://codepen.io>).

You could even add a header above that or more stuff below. The trick with flexbox is either:

  * `flex: 1` on the child you want to grow to fill the space (the content, in our case).
  * or, `margin-top: auto` to push the child away as far as it will go from the neighbor (or whichever direction margin is needed).

Remember we have [a complete guide](<https://css-tricks.com/snippets/css/a-guide-to-flexbox/>) for all this flexbox stuff.

### [](<https://css-tricks.com/couple-takes-sticky-footer/#there-is-grid>)There is grid

Grid layout is even newer (and [less widely supported](<http://caniuse.com/#feat=css-grid>)) than flexbox. We have [a complete guide](<https://css-tricks.com/snippets/css/complete-guide-grid/>) for it too. You can also fairly easily use it for a sticky footer.

    <body>
      <div class="content">
        content
      </div>
      <footer class="footer"></footer>
    </body>

    html {
      height: 100%;
    }
    body {
      min-height: 100%;
      display: grid;
      grid-template-rows: 1fr auto;
    }
    .footer {
      grid-row-start: 2;
      grid-row-end: 3;
    }

This demo should work in Chrome Canary or Firefox Developer Edition, and can probably be backported to the older version of grid layout for Edge:

See the Pen [Sticky Footer with Grid](<http://codepen.io/chriscoyier/pen/YWKNrE/>) by Chris Coyier ([@chriscoyier](<http://codepen.io/chriscoyier>)) on [CodePen](<http://codepen.io>).
