# Tasks, microtasks, queues and schedules

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://jakearchibald.com/2015/tasks-microtasks-queues-and-schedules/>
> 对应题目：JS 深入 第 10 题 · 微任务、宏任务与 EventLoop
> 抓取时间：2026-09-22

---

When I told my colleague [Matt Gaunt](<https://twitter.com/gauntface>) I was thinking of writing a piece on microtask queueing and execution within the browser's event loop, he said "I'll be honest with you Jake, I'm not going to read that". Well, I've written it anyway, so we're all going to sit here and enjoy it, ok?

Actually, if video's more your thing, [Philip Roberts](<https://twitter.com/philip_roberts>) gave a [great talk at JSConf on the event loop](<https://www.youtube.com/watch?v=8aGhZQkoFbQ>) \- microtasks aren't covered, but it's a great introduction to the rest. Anyway, on with the show…

Take this little bit of JavaScript:

    console.log('script start');

    setTimeout(function () {
      console.log('setTimeout');
    }, 0);

    Promise.resolve()
      .then(function () {
        console.log('promise1');
      })
      .then(function () {
        console.log('promise2');
      });

    console.log('script end');

In what order should the logs appear?

The correct answer: `script start`, `script end`, `promise1`, `promise2`, `setTimeout`, but it's pretty wild out there in terms of browser support.

Microsoft Edge, Firefox 40, iOS Safari and desktop Safari 8.0.8 log `setTimeout` before `promise1` and `promise2` \- although it appears to be a race condition. This is really weird, as Firefox 39 and Safari 8.0.7 get it consistently right.

To understand this you need to know how the event loop handles tasks and microtasks. This can be a lot to get your head around the first time you encounter it. Deep breath…

Each 'thread' gets its own **event loop** , so each web worker gets its own, so it can execute independently, whereas all windows on the same origin share an event loop as they can synchronously communicate. The event loop runs continually, executing any tasks queued. An event loop has multiple task sources which guarantees execution order within that source (specs [such as IndexedDB](<http://w3c.github.io/IndexedDB/#database-access-task-source>) define their own), but the browser gets to pick which source to take a task from on each turn of the loop. This allows the browser to give preference to performance sensitive tasks such as user-input. Ok ok, stay with me…

**Tasks** are scheduled so the browser can get from its internals into JavaScript/DOM land and ensures these actions happen sequentially. Between tasks, the browser _may_ render updates. Getting from a mouse click to an event callback requires scheduling a task, as does parsing HTML, and in the above example, `setTimeout`.

`setTimeout` waits for a given delay then schedules a new task for its callback. This is why `setTimeout` is logged after `script end`, as logging `script end` is part of the first task, and `setTimeout` is logged in a separate task. Right, we're almost through this, but I need you to stay strong for this next bit…

**Microtasks** are usually scheduled for things that should happen straight after the currently executing script, such as reacting to a batch of actions, or to make something async without taking the penalty of a whole new task. The microtask queue is processed after callbacks as long as no other JavaScript is mid-execution, and at the end of each task. Any additional microtasks queued during microtasks are added to the end of the queue and also processed. Microtasks include mutation observer callbacks, and as in the above example, promise callbacks.

Once a promise settles, or if it has already settled, it queues a _microtask_ for its reactionary callbacks. This ensures promise callbacks are async even if the promise has already settled. So calling `.then(yey, nay)` against a settled promise immediately queues a microtask. This is why `promise1` and `promise2` are logged after `script end`, as the currently running script must finish before microtasks are handled. `promise1` and `promise2` are logged before `setTimeout`, as microtasks always happen before the next task.

So, step by step:

    console.log('script start');

    setTimeout(function () {
      console.log('setTimeout');
    }, 0);

    Promise.resolve()
      .then(function () {
        console.log('promise1');
      })
      .then(function () {
        console.log('promise2');
      });

    console.log('script end');

Tasks |  Run script setTimeout callback  
---|---  
Microtasks |  Promise then Promise then  
JS stack |   
Log |  script start script end promise1 promise2 setTimeout  

Yes that's right, I created an animated step-by-step diagram. How did you spend _your_ Saturday? Went out in the _sun_ with your _friends_? Well _I didn't_. Um, in case it isn't clear from my amazing UI design, click the arrows above to advance.

Some browsers log `script start`, `script end`, `setTimeout`, `promise1`, `promise2`. They're running promise callbacks after `setTimeout`. It's likely that they're calling promise callbacks as part of a new task rather than as a microtask.

This is sort-of excusable, as promises come from ECMAScript rather than HTML. ECMAScript has the concept of "jobs" which are similar to microtasks, but the relationship isn't explicit aside from [vague mailing list discussions](<https://esdiscuss.org/topic/the-initialization-steps-for-web-browsers#content-16>). However, the general consensus is that promises should be part of the microtask queue, and for good reason.

Treating promises as tasks leads to performance problems, as callbacks may be unnecessarily delayed by task-related things such as rendering. It also causes non-determinism due to interaction with other task sources, and can break interactions with other APIs, but more on that later.

Here's [an Edge ticket](<https://connect.microsoft.com/IE/feedback/details/1658365>) for making promises use microtasks. WebKit nightly is doing the right thing, so I assume Safari will pick up the fix eventually, and it appears to be fixed in Firefox 43.

Really interesting that both Safari and Firefox suffered a regression here that's since been fixed. I wonder if it's just a coincidence.

Testing is one way. See when logs appear relative to promises & `setTimeout`, although you're relying on the implementation to be correct.

The certain way, is to look up the spec. For instance, [step 14 of `setTimeout`](<https://html.spec.whatwg.org/multipage/webappapis.html#timer-initialisation-steps>) queues a task, whereas [step 5 of queuing a mutation record](<https://dom.spec.whatwg.org/#queue-a-mutation-record>) queues a microtask.

As mentioned, in ECMAScript land, they call microtasks "jobs". In [step 8.a of `PerformPromiseThen`](<http://www.ecma-international.org/ecma-262/6.0/#sec-performpromisethen>), `EnqueueJob` is called to queue a microtask.

Now, let's look at a more complicated example. _Cut to a concerned apprentice_ "No, they're not ready!". Ignore him, you're ready. Let's do this…

Before writing this post I'd have gotten this wrong. Here's a bit of html:

    <div class="outer">
      <div class="inner"></div>
    </div>

Given the following JS, what will be logged if I click `div.inner`?

    // Let's get hold of those elements
    var outer = document.querySelector('.outer');
    var inner = document.querySelector('.inner');

    // Let's listen for attribute changes on the
    // outer element
    new MutationObserver(function () {
      console.log('mutate');
    }).observe(outer, {
      attributes: true,
    });

    // Here's a click listener…
    function onClick() {
      console.log('click');

      setTimeout(function () {
        console.log('timeout');
      }, 0);

      Promise.resolve().then(function () {
        console.log('promise');
      });

      outer.setAttribute('data-random', Math.random());
    }

    // …which we'll attach to both elements
    inner.addEventListener('click', onClick);
    outer.addEventListener('click', onClick);

Go on, give it a go before peeking at the answer. _Clue:_ Logs can happen more than once.

Click the inner square to trigger a click event:

Was your guess different? If so, you may still be right. Unfortunately the browsers don't really agree here:

  * ![Chrome](https://jakearchibald.com/c/chrome-BOC7ilOB.png)
    * click
    * promise
    * mutate
    * click
    * promise
    * mutate
    * timeout
    * timeout
  * ![Firefox](https://jakearchibald.com/c/firefox-v2mbQWDY.png)
    * click
    * mutate
    * click
    * mutate
    * timeout
    * promise
    * promise
    * timeout
  * ![Safari](https://jakearchibald.com/c/safari-2Ki1JBjK.png)
    * click
    * mutate
    * click
    * mutate
    * promise
    * promise
    * timeout
    * timeout
  * ![Edge](https://jakearchibald.com/c/edge-HzhJCJV5.png)
    * click
    * click
    * mutate
    * timeout
    * promise
    * timeout
    * promise

Dispatching the 'click' event is a task. Mutation observer and promise callbacks are queued as microtasks. The `setTimeout` callback is queued as a task. So here's how it goes:

    // Let's get hold of those elements
    var outer = document.querySelector('.outer');
    var inner = document.querySelector('.inner');

    // Let's listen for attribute changes on the
    // outer element
    new MutationObserver(function () {
      console.log('mutate');
    }).observe(outer, {
      attributes: true,
    });

    // Here's a click listener…
    function onClick() {
      console.log('click');

      setTimeout(function () {
        console.log('timeout');
      }, 0);

      Promise.resolve().then(function () {
        console.log('promise');
      });

      outer.setAttribute('data-random', Math.random());
    }

    // …which we'll attach to both elements
    inner.addEventListener('click', onClick);
    outer.addEventListener('click', onClick);

Tasks |  Dispatch click setTimeout callback setTimeout callback  
---|---  
Microtasks |  Promise then Mutation observers Promise then Mutation observers  
JS stack |   
Log |  click promise mutate click promise mutate timeout timeout  

So it's Chrome that gets it right. The bit that was 'news to me' is that microtasks are processed after callbacks (as long as no other JavaScript is mid-execution), I thought it was limited to end-of-task. This rule comes from the HTML spec for calling a callback:

> If the [stack of script settings objects](<https://html.spec.whatwg.org/multipage/webappapis.html#stack-of-script-settings-objects>) is now empty, [perform a microtask checkpoint](<https://html.spec.whatwg.org/multipage/webappapis.html#perform-a-microtask-checkpoint>)
> 
> — [HTML: Cleaning up after a callback](<https://html.spec.whatwg.org/multipage/webappapis.html#clean-up-after-running-a-callback>) step 3

…and a microtask checkpoint involves going through the microtask queue, unless we're already processing the microtask queue. Similarly, ECMAScript says this of jobs:

> Execution of a Job can be initiated only when there is no running execution context and the execution context stack is empty…
> 
> — [ECMAScript: Jobs and Job Queues](<http://www.ecma-international.org/ecma-262/6.0/#sec-jobs-and-job-queues>)

…although the "can be" becomes "must be" when in an HTML context.

**Firefox** and **Safari** are correctly exhausting the microtask queue between click listeners, as shown by the mutation callbacks, but promises appear to be queued differently. This is sort-of excusable given that the link between jobs & microtasks is vague, but I'd still expect them to execute between listener callbacks. [Firefox ticket](<https://bugzilla.mozilla.org/show_bug.cgi?id=1193394>). [Safari ticket](<https://bugs.webkit.org/show_bug.cgi?id=147933>).

With **Edge** we've already seen it queue promises incorrectly, but it also fails to exhaust the microtask queue between click listeners, instead it does so after calling all listeners, which accounts for the single `mutate` log after both `click` logs. [Bug ticket](<https://connect.microsoft.com/IE/feedbackdetail/view/1658386/microtasks-queues-should-be-processed-following-event-listeners>).

Ohh boy. Using the same example from above, what happens if we execute:

This will start the event dispatching as before, but using script rather than a real interaction.

And here's what the browsers say:

  * ![Chrome](https://jakearchibald.com/c/chrome-BOC7ilOB.png)
    * click
    * click
    * promise
    * mutate
    * promise
    * timeout
    * timeout
  * ![Firefox](https://jakearchibald.com/c/firefox-v2mbQWDY.png)
    * click
    * click
    * mutate
    * timeout
    * promise
    * promise
    * timeout
  * ![Safari](https://jakearchibald.com/c/safari-2Ki1JBjK.png)
    * click
    * click
    * mutate
    * promise
    * promise
    * timeout
    * timeout
  * ![Edge](https://jakearchibald.com/c/edge-HzhJCJV5.png)
    * click
    * click
    * mutate
    * timeout
    * promise
    * timeout
    * promise

And I swear I keep getting different results from Chrome, I've updated this chart a ton of times thinking I was testing Canary by mistake. If you get different results in Chrome, tell me which version in the comments.

Here's how it should happen:

    // Let's get hold of those elements
    var outer = document.querySelector('.outer');
    var inner = document.querySelector('.inner');

    // Let's listen for attribute changes on the
    // outer element
    new MutationObserver(function () {
      console.log('mutate');
    }).observe(outer, {
      attributes: true,
    });

    // Here's a click listener…
    function onClick() {
      console.log('click');

      setTimeout(function () {
        console.log('timeout');
      }, 0);

      Promise.resolve().then(function () {
        console.log('promise');
      });

      outer.setAttribute('data-random', Math.random());
    }

    // …which we'll attach to both elements
    inner.addEventListener('click', onClick);
    outer.addEventListener('click', onClick);

    inner.click();

Tasks |  Run script setTimeout callback setTimeout callback  
---|---  
Microtasks |  Promise then Mutation observers Promise then  
JS stack |   
Log |  click click promise mutate promise timeout timeout  

So the correct order is: `click`, `click`, `promise`, `mutate`, `promise`, `timeout`, `timeout`, which Chrome seems to get right.

After each listener callback is called…

> If the [stack of script settings objects](<https://html.spec.whatwg.org/multipage/webappapis.html#stack-of-script-settings-objects>) is now empty, [perform a microtask checkpoint](<https://html.spec.whatwg.org/multipage/webappapis.html#perform-a-microtask-checkpoint>)
> 
> — [HTML: Cleaning up after a callback](<https://html.spec.whatwg.org/multipage/webappapis.html#clean-up-after-running-a-callback>) step 3

Previously, this meant that microtasks ran between listener callbacks, but `.click()` causes the event to dispatch synchronously, so the script that calls `.click()` is still in the stack between callbacks. The above rule ensures microtasks don't interrupt JavaScript that's mid-execution. This means we don't process the microtask queue between listener callbacks, they're processed after both listeners.

Yeah, it'll bite you in obscure places (ouch). I encountered this while trying to create [a simple wrapper library for IndexedDB that uses promises](<https://github.com/jakearchibald/indexeddb-promised/blob/master/lib/idb.js>) rather than weird `IDBRequest` objects. It [_almost_ makes IDB fun to use](<https://github.com/jakearchibald/indexeddb-promised/blob/master/test/idb.js#L36>).

When IDB fires a success event, the related [transaction object becomes inactive after dispatching](<http://w3c.github.io/IndexedDB/#fire-a-success-event>) (step 4). If I create a promise that resolves when this event fires, the callbacks should run before step 4 while the transaction is still active, but that doesn't happen in browsers other than Chrome, rendering the library kinda useless.

You can actually work around this problem in Firefox, because promise polyfills such as [es6-promise](<https://github.com/jakearchibald/es6-promise>) use mutation observers for callbacks, which correctly use microtasks. Safari seems to suffer from race conditions with that fix, but that could just be their [broken implementation of IDB](<http://www.raymondcamden.com/2014/09/25/IndexedDB-on-iOS-8-Broken-Bad>). Unfortunately, things consistently fail in IE/Edge, as mutation events aren't handled after callbacks.

Hopefully we'll start to see some interoperability here soon.

In summary:

  * Tasks execute in order, and the browser may render between them
  * Microtasks execute in order, and are executed:
    * after every callback, as long as no other JavaScript is mid-execution
    * at the end of each task

Hopefully you now know your way around the event loop, or at least have an excuse to go and have a lie down.

Actually, is anyone still reading? Hello? Hello?

Thanks to Anne van Kesteren, Domenic Denicola, Brian Kardell, and Matt Gaunt for proofreading & corrections. Yeah, Matt actually read it in the end, I didn't even need to go full "Clockwork Orange" on him.
