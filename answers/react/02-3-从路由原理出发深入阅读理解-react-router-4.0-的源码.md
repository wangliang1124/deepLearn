# 从路由原理出发，深入阅读理解 react-router 4.0 的源码

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://github.com/forthealllight/blog/issues/26>
> 对应题目：React 第 2 题 · 如何配置 React-Router
> 抓取时间：2026-09-22

---

# 从路由原理出发，深入阅读理解react-router 4.0的源码

* * *

react-router等前端路由的原理大致相同，可以实现无刷新的条件下切换显示不同的页面。路由的本质就是页面的URL发生改变时，页面的显示结果可以根据URL的变化而变化，但是页面不会刷新。通过前端路由可以实现单页(SPA)应用,本文首先从前端路由的原理出发，详细介绍了前端路由原理的变迁。接着从react-router4.0的源码出发，深入理解react-router4.0是如何实现前端路由的。

>   * 通过Hash实现前端路由
>   * 通过H5的history实现前端路由
>   * React-router4.0的使用
>   * React-router4.0源码分析
> 

* * *

## 一、通过Hash实现前端路由

### 1、hash的原理

早期的前端路由是通过hash来实现的：

**_改变url的hash值是不会刷新页面的。_**

因此可以通过hash来实现前端路由，从而实现无刷新的效果。hash属性位于location对象中，在当前页面中，可以通过：

    window.location.hash='edit'

来实现改变当前url的hash值。执行上述的hash赋值后，页面的url发生改变。

赋值前：<http://localhost:3000>  
赋值后：<http://localhost:3000/#edit>

在url中多了以#结尾的hash值，但是赋值前后虽然页面的hash值改变导致页面完整的url发生了改变，但是页面是不会刷新的。此外，还有一个名为hashchange的事件，可以监听hash的变化,我们可以通过下面两种方式来监听hash的变化：

    window.onhashchange=function(event){
       console.log(event);
    }
    window.addEventListener('hashchange',function(event){
       console.log(event);
    })

当hash值改变时，输出一个HashChangeEvent。该HashChangeEvent的具体值为：

    {isTrusted: true, oldURL: "http://localhost:3000/", newURL:   "http://localhost:3000/#teg", type: "hashchange".....}

有了监听事件，且改变hash页面不刷新，这样我们就可以在监听事件的回调函数中，执行我们展示和隐藏不同UI显示的功能，从而实现前端路由。

此外，除了可以通过window.location.hash来改变当前页面的hash值外，还可以通过html的a标签来实现：

### 2、hash的缺点

hash的兼容性较好，因此在早期的前端路由中大量的采用，但是使用hash也有很多缺点。

  * 搜索引擎对带有hash的页面不友好
  * 带有hash的页面内难以追踪用户行为

## 二、通过history实现前端路由

HTML5的History接口，History对象是一个底层接口，不继承于任何的接口。History接口允许我们操作浏览器会话历史记录。

### (1)History的属性和方法

History提供了一些属性和方法。

History的属性：

  * History.length: 返回在会话历史中有多少条记录，包含了当前会话页面。此外如果打开一个新的Tab，那么这个length的值为1
  * History.state:  
保存了会出发popState事件的方法，所传递过来的属性对象（后面会在pushState和replaceState方法中详细的介绍）

History方法：

  * History.back(): 返回浏览器会话历史中的上一页，跟浏览器的回退按钮功能相同

  * History.forward():指向浏览器会话历史中的下一页，跟浏览器的前进按钮相同

  * History.go(): 可以跳转到浏览器会话历史中的指定的某一个记录页

  * History.pushState():pushState可以将给定的数据压入到浏览器会话历史栈中，该方法接收3个参数，对象，title和一串url。pushState后会改变当前页面url，但是不会伴随着刷新

  * History.replaceState():replaceState将当前的会话页面的url替换成指定的数据，replaceState后也会改变当前页面的url，但是也不会刷新页面。

上面的方法中，pushState和repalce的相同点：

**_就是都会改变当前页面显示的url，但都不会刷新页面。_**

不同点：

**_pushState是压入浏览器的会话历史栈中，会使得History.length加1，而replaceState是替换当前的这条会话历史，因此不会增加History.length._**

### (2)BOM对象history

history在浏览器的BOM对象模型中的重要属性，history完全继承了History接口，因此拥有History中的所有的属性和方法。

这里我们主要来看看history.length属性以及history.pushState、history.replaceState方法。

  * history.pushState(stateObj,title,url) or history.replaceState(stateObj,title,url)

pushState和replaceState接受3个参数，分别为state对象，title标题，改变的url。

window.history.pushState({foo:'bar'}, "page 2", "bar.html");

此时，当前的url变为：

执行上述方法前：<http://localhost:3000>  
执行上述方法后：<http://localhost:3000/bar.html>

如果我们输出window.history.state:

console.log(window.history.state);  
// {foo:'bar'}

window.history.state就是我们pushState的第一个对象参数。

上述前后两次输出的window.history.length是相等的。

此外。

每次触发history.back()或者浏览器的后退按钮等，会触发一个popstate事件，这个事件在后退或者前进的时候发生：

    window.onpopstate=function(event){

    }

注意：  
history.pushState和history.replaceState方法并不会触发popstate事件。

**_如果用history做为路由的基础，那么需要用到的是history.pushState和history.replaceState,在不刷新的情况下可以改变url的地址，且如果页面发生回退back或者forward时，会触发popstate事件。_**

hisory为依据来实现路由的优点：

缺点：

  * 兼容性不如hash
  * 需要后端做相应的配置，否则直接访问子页面会出现404错误

## 三、React-router4.0的使用

了解了前端路由实现的原理之后，下面来介绍一下React-router4.0。在React-router4.0的代码库中，根据使用场景包含了以下几个独立的包：

  * react-router : react-router4.0的核心代码
  * react-router-dom : 构建网页应用，存在DOM对象场景下的核心包
  * react-router-native : 适用于构建react-native应用
  * react-router-config : 配置静态路由
  * react-router-redux : 结合redux来配置路由，已废弃，不推荐使用。

在react-router4.0中，遵循Just Component的设计理念：

**_所提供的API都是以组件的形式给出。_**

比如BrowserRouter、Router、Link、Switch等API都是以组件的形式来使用。

### 1、React-router-dom常用的组件API

下面我们以React-router4.0中的React-router-dom包来介绍常用的BrowserRouter、HashRouter、Link和Router等。

#### (1) <BrowserRouter>

用<BrowserRouter> 组件包裹整个App系统后，就是通过html5的history来实现无刷新条件下的前端路由。

<BrowserRouter>组件具有以下几个属性：

如果设置了basename属性，那么此时的：

<http://localhost:3000> 和 <http://localhost:3000/test> 表示的是同一个地址，渲染的内容相同。

  * getUserConfirmation: func 这个属性，用于确认导航的功能。默认使用window.confirm

  * forceRefresh: bool 默认为false，表示改变路由的时候页面不会重新刷新，如果当前浏览器不支持history，那么当forceRefresh设置为true的时候，此时每次去改变url都会重新刷新整个页面。

  * keyLength: number 表示location的key属性的长度，在react-router中每个url下都有为一个location与其对应，并且每一个url的location的key值都不相同，这个属性一般都使用默认值，设置的意义不大。

  * children: node children的属性必须是一个ReactNode节点，表示唯一渲染一个元素。

与<BrowserRouter>对应的是<HashRouter>,<HashRouter>使用url中的hash属性来保证不重新刷新的情况下同时渲染页面。

#### (2) <Route>

<Route> 组件十分重要，<Route> 做的事情就是匹配相应的location中的地址，匹配成功后渲染对应的组件。下面我们来看<Route>中的属性。

首先来看如何执行匹配，决定<Route>地址匹配的属性：

举例来说，当exact不设置时：

    <Route  path='/home' component={Home}/> 
    <Route  path='/home/first' component={First}/> 

此时url地址为：<http://localhost:3000/home/first> 的时候，不仅仅会匹配到 path='/home/first'时的组件First,同时还会匹配到path='home'时候的Router。

如果设置了exact：

     <Route  path='/home' component={Home}/> 

只有<http://localhost:3000/home/first> 不会匹配Home组件，只有url地址完全与path相同，只有[http://localhost:3000/home才能匹配Home组件成功。](<http://localhost:3000/home%E6%89%8D%E8%83%BD%E5%8C%B9%E9%85%8DHome%E7%BB%84%E4%BB%B6%E6%88%90%E5%8A%9F%E3%80%82>)

  * strict ：与exact不同，strict属性仅仅是对exact属性的一个补充，设置了strict属性后，严格限制了但斜线“／”。

举例来说,当不设置strict的时候：

     <Route  path='/home/' component={Home}/> 

此时<http://localhost:3000/home> 和 <http://localhost:3000/home/>  
都能匹配到组件Home。匹配对于斜线“/”比较宽松。如果设置了strict属性：

    <Route  path='/home/' component={Home}/> 

那么此时严格匹配斜线是否存在，<http://localhost:3000/home> 将无法匹配到Home组件。

当Route组件与某一url匹配成功后，就会继续去渲染。那么什么属性决定去渲染哪个组件或者样式呢，Route的component、render、children决定渲染的内容。

  * component：该属性接受一个React组件，当url匹配成功，就会渲染该组件
  * render：func 该属性接受一个返回React Element的函数，当url匹配成功，渲染覆该返回的元素
  * children：与render相似，接受一个返回React Element的函数，但是不同点是，无论url与当前的Route的path匹配与否，children的内容始终会被渲染出来。

并且这3个属性所接受的方法或者组件，都会有location，match和history这3个参数。如果组件，那么组件的props中会存在从Link传递过来的location，match以及history。

#### (3) <Link>

<Route>定义了匹配规则和渲染规则，而<Link> 决定的是如何在页面内改变url，从而与相应的<Route>匹配。<Link>类似于html中的a标签，此外<Link>在改变url的时候，可以将一些属性传递给匹配成功的Route，供相应的组件渲染的时候使用。

  * to: string  
to属性的值可以为一个字符串，跟html中的a标签的href一样，即使to属性的值是一个字符串，点击Link标签跳转从而匹配相应path的Route，也会将history，location，match这3个对象传递给Route所对应的组件的props中。

举例来说：

    <Link to='/home'>Home</Link>

如上所示，当to接受一个string，跳转到url为'/home'所匹配的Route，并渲染其关联的组件内接受3个对象history，location，match。  
这3个对象会在下一小节会详细介绍。

  * to: object  
to属性的值也可以是一个对象，该对象可以包含一下几个属性：pathname、seacth、hash和state，其中前3个参数与如何改变url有关，最后一个state参数是给相应的改变url时，传递一个对象参数。

举例来说：

     <Link to={{pathname:'/home',search:'?sort=name',hash:'#edit',state:{a:1}}}>Home</Link>

在上个例子中，to为一个对象，点击Link标签跳转后，改变后的url为：'/home?sort=name#edit'。 但是在与相应的Route匹配时，只匹配path为'/home'的组件，'/home?sort=name#edit'。在'/home'后所带的参数不作为匹配标准，仅仅是做为参数传递到所匹配到的组件中，此外，state={a:1}也同样做为参数传递到新渲染的组件中。

#### (4) React-router中传递给组件props的history对象

介绍了 <BrowserRouter> 、 <Route> 和 <Link> 之后，使用这3个组件API就可以构建一个简单的React-router应用。这里我们之前说，每当点击Link标签跳转或者在js中使用React-router的方法跳转，从当前渲染的组件，进入新组件。在新组件被渲染的时候，会接受一个从旧组件传递过来的参数。

我们前面提到，Route匹配到相应的改变后的url，会渲染新组件，该新组件中的props中有history、location、match3个对象属性，其中hisotry对象属性最为关键。

同样以下面的例子来说明：

    <Link to={{pathname:'/home',search:'?sort=name',hash:'#edit',state:{a:1}}}>Home</Link>

    <Route exact path='/home' component={Home}/>

我们使用了<BrowserRouter>，该组件利用了window.history对象，当点击Link标签跳转后，会渲染新的组件Home，我们可以在Home组件中输出props中的history：

    // props中的history
    action: "PUSH"
    block: ƒ block()
    createHref: ƒ createHref(location)
    go: ƒ go(n)
    goBack: ƒ goBack()
    goForward: ƒ goForward()
    length: 12
    listen: ƒ listen(listener)
    location: {pathname: "/home", search: "?sort=name", hash: "#edit", state: {…}, key: "uxs9r5"}
    push: ƒ push(path, state)
    replace: ƒ replace(path, state)

从上面的属性明细中：

  * push:f 这个方法用于在js中改变url，之前在Link组件中可以类似于HTML标签的形式改变url。push方法映射于window.history中的pushState方法。

  * replace: f 这个方法也是用于在js中改变url，replace方法映射于window.history中的replaceState方法。

  * block：f 这个方法也很有用，比如当用户离开当前页面的时候，给用户一个文字提示，就可以采用history.block("你确定要离开当前页吗？")这样的提示。

  * go / goBack / goForward

在组件props中history的go、goBack、goForward方法，分别window.history.go、window.history.back、window.history.forward对应。

  * action: "PUSH" || "POP"  
action这个属性左右很大，如果是通过Link标签或者在js中通过this.props.push方法来改变当前的url，那么在新组件中的action就是"PUSH",否则就是"POP".

action属性很有用，比如我们在做翻页动画的时候，前进的动画是SlideIn，后退的动画是SlideOut，我们可以根据组件中的action来判断采用何种动画：

    function newComponent (props)=>{
       return (
         <ReactCSSTransitionGroup
              transitionAppear={true}
              transitionAppearTimeout={600}
              transitionEnterTimeout={600}
              transitionLeaveTimeout={200}
              transitionName={props.history.action==='PUSH'?'SlideIn':'SlideOut'}
             >
               <Component {...props}/>
        </ReactCSSTransitionGroup>
       )
    }

除了key这个用作唯一表示外，其他的属性都是我们从上一个Link标签中传递过来的参数。

## 四、React-router4.0源码分析

在第三节中我们介绍了React-router的大致使用方法，读一读React-router4.0的源码。

这里我们主要分析一下React-router4.0中是如何根据window.history来实现前端路由的，因此设计到的组件为BrowserRouter、Router、Route和Link

### 1、React-router中的history

从上一节的介绍中我们知道，点击Link标签传递给新渲染的组件的props中有一个history对象，这个对象的内容很丰富，比如：action、goBack、go、location、push和replace方法等。

React-router构建了一个History类，用于在window.history的基础上，构建属性更为丰富的实例。该History类实例化后具有action、goBack、location等等方法。

React-router中将这个新的History类的构建方法，独立成一个node包，包名为history。

可以通过上述方法来引入，我们来看看这个History类的实现。

    const createBrowserHistory = (props = {}) => {
        const globalHistory = window.history;
        ......
        //默认props中属性的值
        const {
          forceRefresh = false,
          getUserConfirmation = getConfirmation,
          keyLength = 6,
          basename = '',
        } = props;
        const history = {
            length: globalHistory.length,
            action: "POP",
            location: initialLocation,
            createHref,
            push,
            replace,
            go,
            goBack,
            goForward,
            block,
            listen
        };                                         ---- (1)
        const basename = props.basename;   
        const canUseHistory = supportsHistory();   ----（2)

        const createKey = () =>Math.random().toString(36).substr(2, keyLength);    ----（3）

        const transitionManager = createTransitionManager();  ----（4）
        const setState = nextState => {
            Object.assign(history, nextState);

            history.length = globalHistory.length;

            transitionManager.notifyListeners(history.location, history.action);
        };                                      ----（5）

        const handlePopState = event => {
            handlePop(getDOMLocation(event.state));
        };
        const handlePop = location => {
        if (forceNextPop) {
          forceNextPop = false;
          setState();
        } else {
          const action = "POP";

          transitionManager.confirmTransitionTo(
                location,
                action,
                getUserConfirmation,
                ok => {
                  if (ok) {
                    setState({ action, location });
                  } else {
                    revertPop(location);
                  }
                }
              );
            }
        };                                    ------（6）
        const initialLocation = getDOMLocation(getHistoryState());
        let allKeys = [initialLocation.key]; ------（7）

        // 与pop相对应，类似的push和replace方法
        const push ... replace ...            ------(8)

        return history                        ------ （9）

    }

从上述判别式我们可以看出，window.history在chrome、mobile safari和windows phone下是绝对支持的，但不支持安卓2.x以及安卓4.0

  * (3)中用于创建与history中每一个url记录相关联的指定位数的唯一标识key, 默认的keyLength为6位

  * (4)中 createTransitionManager方法，返回一个集成对象，对象中包含了关于history地址或者对象改变时候的监听函数等，具体代码如下：

        const createTransitionManager = () => {
               const setPrompt = nextPrompt => {

               };

               const confirmTransitionTo = (
                 location,
                 action,
                 getUserConfirmation,
                 callback
               ) => {
                  if (typeof getUserConfirmation === "function") {
                       getUserConfirmation(result, callback);
                     } else {
                       callback(true);
                     }
                   } 
               };

               let listeners = [];
               const appendListener = fn => {
                 let isActive = true;

                 const listener = (...args) => {
                   if (isActive) fn(...args);
                 };

                 listeners.push(listener);

                 return () => {
                   isActive = false;
                   listeners = listeners.filter(item => item !== listener);
                 };
               };

               const notifyListeners = (...args) => {
                 listeners.forEach(listener => listener(...args));
               };

               return {
                 setPrompt,
                 confirmTransitionTo,
                 appendListener,
                 notifyListeners
               };

};

setPrompt函数，用于设置url跳转时弹出的文字提示，confirmTransaction函数，会将当前生成新的history对象中的location，action，callback等参数，作用就是在回调的callback方法中，根据要求，改变传入的location和action对象。

接着我们看到有一个listeners数组，保存了一系列与url相关的监听事件数组，通过接下来的appendListener方法，可以往这个数组中增加事件，通过notifyListeners方法可以遍历执行listeners数组中的所有事件。

  * (5) setState方法，发生在history的url或者history的action发生改变的时候，此方法会更新history对象中的属性，同时会触发notifyListeners方法，传入当前的history.location和history.action。遍历并执行所有监听url改变的事件数组listeners。

  * (6)这个getDOMLocation方法就是根据当前在window.state中的值，生成新history的location属性对象，allKeys这是始终保持了在url改变时候的历史url相关联的key，保存在全局，allKeys在执行生“POP”或者“PUSH”、“Repalce”等会改变url的方法时，会保持一个实时的更新。

  * (7) handlePop方法，用于处理“POP”事件，我们知道在window.history中点击后退等会触发“POP”事件，这里也是一样，执行action为“POP”，当后退的时候就会触发该函数。

  * (8)中包含了与pop方法类似的，push和replace方法，push方法同样做的事情就是执行action为“PUSH”（“REPLACE”），该变allKeys数组中的值，唯一不同的是actio为“PUSH”的方法push是往allKeys数组中添加，而action为“REPLACE”的方法replace则是替换掉当前的元素。

  * (9)返回这个新生成的history对象。

### 2、React-router中Link组件

其实最难弄懂的是React-router中如何重新构建了一个history工厂函数，在第一小节中我们已经详细的介绍了history生成函数createBrowserHistory的源码，接着来看Link组件就很容易了。

首先Link组件类似于HTML中的a标签，目的也很简单，就是去主动触发改变url的方法，主动改变url的方法，从上述的history的介绍中可知为push和replace方法，因此Link组件的源码为：

    class Link extends React.Component {

       handleClick = event => {
       ...

         const { history } = this.context.router;
         const { replace, to } = this.props;
         if (replace) {
           history.replace(replace);
         } else {
          history.push(to);
         }
       }
      };
      render(){
        const { replace, to, innerRef, ...props } = this.props;
         <a {...props} onClick={this.handleClick}/>
      }
    }

上述代码很简单，从React的context API全局对象中拿到history，然后如果传递给Link组件的属性中有replace为true，则执行history.replace(to),to 是一个包含pathname的对象，如果传递给Link组件的replace属性为false，则执行history.push(to)方法。

### 3、React-router中Route组件

Route组件也很简单，其props中接受一个最主要的属性path，Route做的事情只有一件：

**_当url改变的时候，将path属性与改变后的url做对比，如果匹配成功，则渲染该组件的componet或者children属性所赋值的那个组件。_**

具体源码如下：

    class Route extends React.Component {

      ....
      constructor(){

      }
      render() {
        const { match } = this.state;
        const { children, component, render } = this.props;
        const { history, route, staticContext } = this.context.router;
        const location = this.props.location || route.location;
        const props = { match, location, history, staticContext };

        if (component) return match ? React.createElement(component, props) : null;

        if (render) return match ? render(props) : null;

        if (typeof children === "function") return children(props);

        if (children && !isEmptyChildren(children))
          return React.Children.only(children);

        return null;
      }

    }

state中的match就是是否匹配的标记，如果匹配当前的Route的path，那么根据优先级顺序component属性、render属性和children属性来渲染其所指向的React组件。

### 4、React-router中Router组件

Router组件中，是BrowserRouter、HashRouter等组件的底层组件。该组件中，定义了包含匹配规则match函数，以及使用了新history中的listener方法，来监听url的改变，从而，当url改变时，更改Router下不同path组件的isMatch结果。

    class Router extends React.Component {
        componentWillMount() {
            const { children, history } = this.props

            //调用history.listen监听方法，该方法的返回函数是一个移除监听的函数

            this.unlisten = history.listen(() => {
              this.setState({
                match: this.computeMatch(history.location.pathname)
              });
            });
        }
        componentWillUnmount() {
          this.unlisten();
        }
        render() {

        }
    }

上述首先在组件创建前调用了listener监听方法，来监听url的改变，实时的更新isMatch的结果。

### 5、总结

本文从前端路由的原理出发，先后介绍了两种前端路由常用的方法，接着介绍了React-router的基本组件API以及用法，详细介绍了React-router的组件中新构建的history对象，最后结合React-router的API阅读了一下React-router的源码。
