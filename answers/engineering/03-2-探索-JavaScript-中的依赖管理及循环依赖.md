# 探索 JavaScript 中的依赖管理及循环依赖

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://juejin.cn/post/6844903552012255245>
> 对应题目：前端工程 第 3 题 · Javascript 模块化
> 抓取时间：2026-09-22
> （经浏览器渲染后提取）

---

我们通常会把项目中使用的第三方依赖写在 package.json 文件里，然后使用 npm 、cnpm 或者 yarn 这些流行的依赖管理工具来帮我们管理这些依赖。但是它们是如何管理这些依赖的、它们之间有什么区别，如果出现了循环依赖应该怎么解决。

在回答上面几个问题之前，先让我们了解下语义化版本规则。

## 语义化版本

使用第三方依赖时，通常需要指定依赖的版本范围，比如

    "dependencies": {
        "antd": "3.1.2",
        "react": "~16.0.1",
        "redux": "^3.7.2",
        "lodash": "*"
      }

上面的 package.json 文件表明，项目中使用的 antd 的版本号是 3.1.2，但是 3.1.1 和 3.1.2、3.0.1、2.1.1 之间有什么不同呢。语义化版本规则规定，版本格式为：主版本号.次版本号.修订号，并且版本号的递增规则如下：

  * 主版本号：当你做了不兼容的 API 修改
  * 次版本号：当你做了向下兼容的功能性新增
  * 修订号：当你做了向下兼容的问题修正

主版本号的更新通常意味着大的修改和更新，升级主版本后可能会使你的程序报错，因此升级主版本号需谨慎，但是这往往也会带来更好的性能和体验。次版本号的更新则通常意味着新增了某些特性，比如 antd 的版本从 3.1.1 升级到 3.1.2，之前的 Select 组件不支持搜索功能，升级之后支持了搜索。修订号的更新则往往意味着进行了一些 bug 修复。因此次版本号和修订号应该保持更新，这样能让你之前的代码不会报错还能获取到最新的功能特性。

但是，往往我们不会指定依赖的具体版本，而是指定版本范围，比如上面的 package.json 文件里的 react、redux 以及 lodash，这三个依赖分别使用了三个符号来表明依赖的版本范围。语义化版本范围规定：

  * ~：只升级修订号
  * ^：升级次版本号和修订号
  * *：升级到最新版本

因此，上面的 package.json 文件安装的依赖版本范围如下：

  * react@~16.0.1：>=react@16.0.1 && < react@16.1.0
  * redux@^3.7.2：>=redux@3.7.2 && < redux@4.0.0
  * lodash@*：lodash@latest

语义化版本规则定义了一种理想的版本号更新规则，希望所有的依赖更新都能遵循这个规则，但是往往会有许多依赖不是严格遵循这些规定的。因此，如何管理好这些依赖，尤其是这些依赖的版本就显得尤为重要，否则一不小心就会陷入因依赖版本不一致导致的各种问题中。

## 依赖管理

在项目开发中，通常会使用 [npm](<https://link.juejin.cn?target=https%3A%2F%2Fwww.npmjs.com%2F> "https://www.npmjs.com/")、[yarn](<https://link.juejin.cn?target=https%3A%2F%2Fyarnpkg.com%2Fen%2F> "https://yarnpkg.com/en/") 或者 [cnpm](<https://link.juejin.cn?target=http%3A%2F%2Fnpm.taobao.org%2F> "http://npm.taobao.org/") 来管理项目中的依赖，下面我们就来看看它们是如何帮助我们管理这些依赖的。

### npm

[npm](<https://link.juejin.cn?target=https%3A%2F%2Fwww.npmjs.com%2F> "https://www.npmjs.com/") 发展到今天，可以说经历过三个重大的版本变化。

#### npm v1

最早的 npm 版本在管理依赖时使用了一种很简单的方式。我们称之为嵌套模式。比如，在你的项目中有如下的依赖。

    "dependencies": {
        A: "1.0.0",
        C: "1.0.0",
        D: "1.0.0"
    }

这些模块都依赖 B 模块，而且依赖的 B模块的版本还不同。

    A@1.0.0 -> B@1.0.0
    C@1.0.1 -> B@2.0.0
    D@1.0.0 -> B@1.0.0

通过执行 `npm install` 命令，npm v1 生成的 node_modules目录如下：

    node_modules
    ├── A@1.0.0
    │   └── node_modules
    │       └── B@1.0.0
    ├── C@1.0.0
    │   └── node_modules
    │       └── B@2.0.0
    └── D@1.0.0
        └── node_modules
            └── B@1.0.0

很明显，每个模块下面都会有一个 node_modules 目录存放该模块的直接依赖。模块的依赖下面还会存在一个 node_modules 目录来存放模块的依赖的依赖。很明显这种依赖管理简单明了，但存在很大的问题，除了 node_modules 目录长度的嵌套过深之外，还会造成相同的依赖存储多份的问题，比如上面的 B@1.0.0 就存放了两份，这明显也是一种浪费。于是在 npm v3 发布后，npm 的依赖管理做出了重大的改变。

#### npm v3

对于同样的上述依赖，使用 npm v3 执行 `npm install` 命令后生成的 node_modules 目录如下：

    node_modules
    ├── A@1.0.0
    ├── B@1.0.0
    └── C@1.0.0
        └── node_modules
            └── B@2.0.0
    ├── D@1.0.0

显而易见，npm v3 使用了一种扁平的模式，把项目中使用的所有的模块和模块的依赖都放在了 node_modules 目录下的顶层，遇到版本冲突的时候才会在模块下的 node_modules 目录下存放该模块需要用到的依赖。之所以能这么实现是基于包搜索机制的。包搜索机制是指当你在项目中直接 `require('A')` 时，首先会在当前路径下搜索 node_modules 目录中是否存在该依赖，如果不存在则往上查找也就是继续查找该路径的上一层目录下的 node_modules。正因为此，npm v3 才能把之前的嵌套结构拍平，把所有的依赖都放在项目根目录的 node_modules，这样就避免了 node_modules 目录嵌套过深的问题。此外，npm v3 还会解析模块的依赖的多个版本为一个版本，比如 A依赖 B@^1.0.1，D 依赖 B@^1.0.2，则只会有一个 B@1.0.2 的版本存在。虽然 npm v3 解决了这两个问题，但是此时的 npm 仍然存在诸多问题，被人诟病最多的应该就是它的不确定性了。

#### npm v5

什么是确定性。在 JavaScript 包管理的背景下，确定性是指在给定的 package.json 和 lock 文件下始终能得到一致的 node_modules 目录结构。简单点说就是无论在何种环境下执行 `npm install` 都能得到相同的 node_modules 目录结构。npm v5 正是为解决这个问题而产生的，npm v5 生成的 node_modules 目录和 v3 是一致的，区别是 v5 会默认生成一个 package-lock.json 文件，来保证安装的依赖的确定性。比如，对于如下的一个 package.json 文件

    "dependencies": {
        "redux": "^3.7.2"
      }

对应的 package-lock.json 文件内容如下：

    {
      "name": "test",
      "version": "1.0.0",
      "lockfileVersion": 1,
      "requires": true,
      "dependencies": {
        "js-tokens": {
          "version": "3.0.2",
          "resolved": "https://registry.npmjs.org/js-tokens/-/js-tokens-3.0.2.tgz",
          "integrity": "sha1-mGbfOVECEw449/mWvOtlRDIJwls="
        },
        "lodash": {
          "version": "4.17.4",
          "resolved": "https://registry.npmjs.org/lodash/-/lodash-4.17.4.tgz",
          "integrity": "sha1-eCA6TRwyiuHYbcpkYONptX9AVa4="
        },
        "lodash-es": {
          "version": "4.17.4",
          "resolved": "https://registry.npmjs.org/lodash-es/-/lodash-es-4.17.4.tgz",
          "integrity": "sha1-3MHXVS4VCgZABzupyzHXDwMpUOc="
        },
        "loose-envify": {
          "version": "1.3.1",
          "resolved": "https://registry.npmjs.org/loose-envify/-/loose-envify-1.3.1.tgz",
          "integrity": "sha1-0aitM/qc4OcT1l/dCsi3SNR4yEg=",
          "requires": {
            "js-tokens": "3.0.2"
          }
        },
        "redux": {
          "version": "3.7.2",
          "resolved": "https://registry.npmjs.org/redux/-/redux-3.7.2.tgz",
          "integrity": "sha512-pNqnf9q1hI5HHZRBkj3bAngGZW/JMCmexDlOxw4XagXY2o1327nHH54LoTjiPJ0gizoqPDRqWyX/00g0hD6w+A==",
          "requires": {
            "lodash": "4.17.4",
            "lodash-es": "4.17.4",
            "loose-envify": "1.3.1",
            "symbol-observable": "1.1.0"
          }
        },
        "symbol-observable": {
          "version": "1.1.0",
          "resolved": "https://registry.npmjs.org/symbol-observable/-/symbol-observable-1.1.0.tgz",
          "integrity": "sha512-dQoid9tqQ+uotGhuTKEY11X4xhyYePVnqGSoSm3OGKh2E8LZ6RPULp1uXTctk33IeERlrRJYoVSBglsL05F5Uw=="
        }
      }
    }

不难看出，package-lock.json 文件里记录了安装的每一个依赖的确定版本，这样在下次安装时就能通过这个文件来安装一样的依赖了。

![image](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2018/1/18/1610702b9116a868~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

### yarn

[yarn](<https://link.juejin.cn?target=https%3A%2F%2Fyarnpkg.com%2Fen%2F> "https://yarnpkg.com/en/") 是在 2016.10.11 开源的，yarn 的出现是为了解决 npm v3 中的存在的一些问题，那时 npm v5 还没发布。yarn 被定义为快速、安全、可靠的依赖管理。

  * 快速：全局缓存、并行下载、离线模式
  * 安全：安装包被执行前校验其完整性
  * 可靠：lockfile文件、确定性算法

yarn 生成的 node_modules 目录结构和 npm v5 是相同的，同时默认生成一个 yarn.lock 文件。对于上面的例子，只安装 redux 的依赖生成的 yarn.lock 文件内容如下：

    # THIS IS AN AUTOGENERATED FILE. DO NOT EDIT THIS FILE DIRECTLY.
    # yarn lockfile v1

    js-tokens@^3.0.0:
      version "3.0.2"
      resolved "http://registry.npm.alibaba-inc.com/js-tokens/download/js-tokens-3.0.2.tgz#9866df395102130e38f7f996bceb65443209c25b"

    lodash-es@^4.2.1:
      version "4.17.4"
      resolved "http://registry.npm.alibaba-inc.com/lodash-es/download/lodash-es-4.17.4.tgz#dcc1d7552e150a0640073ba9cb31d70f032950e7"

    lodash@^4.2.1:
      version "4.17.4"
      resolved "http://registry.npm.alibaba-inc.com/lodash/download/lodash-4.17.4.tgz#78203a4d1c328ae1d86dca6460e369b57f4055ae"

    loose-envify@^1.1.0:
      version "1.3.1"
      resolved "http://registry.npm.alibaba-inc.com/loose-envify/download/loose-envify-1.3.1.tgz#d1a8ad33fa9ce0e713d65fdd0ac8b748d478c848"
      dependencies:
        js-tokens "^3.0.0"

    redux@^3.7.2:
      version "3.7.2"
      resolved "http://registry.npm.alibaba-inc.com/redux/download/redux-3.7.2.tgz#06b73123215901d25d065be342eb026bc1c8537b"
      dependencies:
        lodash "^4.2.1"
        lodash-es "^4.2.1"
        loose-envify "^1.1.0"
        symbol-observable "^1.0.3"

    symbol-observable@^1.0.3:
      version "1.1.0"
      resolved "http://registry.npm.alibaba-inc.com/symbol-observable/download/symbol-observable-1.1.0.tgz#5c68fd8d54115d9dfb72a84720549222e8db9b32"

不难看出，yarn.lock 文件和 npm v5 生成的 package-lock.json 文件有如下几点不同：

  1. 文件格式不同，npm v5 使用的是 json 格式，yarn 使用的是一种自定义格式
  2. package-lock.json 文件里记录的依赖的版本都是确定的，不会出现语义化版本范围符号(~ ^ *)，而 yarn.lock 文件里仍然会出现语义化版本范围符号
  3. package-lock.json 文件内容更丰富，npm v5 只需要 package.lock 文件就可以确定 node_modules 目录结构，而 yarn 却需要同时依赖 package.json 和 yarn.lock 两个文件才能确定 node_modules 目录结构

关于为什么会有这些不同、yarn 的确定性算法以及和 npm v5 的区别，yarn 官方的一篇文章详细介绍了这几点。由于篇幅有限，这里就不再赘述，感兴趣的可以移步到我的翻译文章 [Yarn 确定性](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Ffengliner%2Fblog%2Fissues%2F3> "https://github.com/fengliner/blog/issues/3")去看。

[yarn](<https://link.juejin.cn?target=https%3A%2F%2Fyarnpkg.com%2Fen%2F> "https://yarnpkg.com/en/") 的出现除了带来安装速度的提升以外，最大的贡献是通过 lock 文件来保证安装依赖的确定性，保证相同的 package.json 文件，在何种环境何种机器上安装依赖都会得到相同的结果也就是相同的 node_modules 目录结构。这在很大程度上避免了一些“在我电脑上是正常的，在其他机器上失败”的 bug。但是在使用 yarn 做依赖管理时，仍然需要注意以下3点。

  * 不要手动修改 yarn.lock 文件
  * yarn.lock 文件应该提交到版本控制的仓库里
  * 升级依赖时，使用`yarn upgrade`命令，避免手动修改 package.json 和 yarn.lock 文件。

### cnpm

[cnpm](<https://link.juejin.cn?target=http%3A%2F%2Fnpm.taobao.org%2F> "http://npm.taobao.org/") 在国内的用户应该还是蛮多的，尤其是对于有搭建私有仓库需求的人来说。cnpm 在安装依赖时使用的是 [npminstall](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Fcnpm%2Fnpminstall> "https://github.com/cnpm/npminstall")，简单来说， cnpm 使用链接 link 的安装方式，最大限度地提高了安装速度，生成的 node_modules 目录采用的是和 npm 不一样的布局。 用 cnpm 装的包都是在 node_modules 文件夹下以 版本号 @包名 命名，然后再做软链接到只以包名命名的文件夹上。同样的例子，使用 cnpm 只安装 redux 依赖时生成的 node_modules 目录结构如下：

![image](https://p1-jj.byteimg.com/tos-cn-i-t2oaga2asx/gold-user-assets/2018/1/18/1610702b91c86114~tplv-t2oaga2asx-jj-mark:3024:0:0:0:q75.png)

cnpm 和 npm 以及 yarn 之间最大的区别就在于生成的 node_modules 目录结构不同，这在某些场景下可能会引发一些问题。此外也不会生成 lock 文件，这就导致在安装确定性方面会比 npm 和 yarn 稍逊一筹。但是 cnpm 使用的 link 安装方式还是很好的，既节省了磁盘空间，也保持了 node_modules 的目录结构清晰，可以说是在嵌套模式和扁平模式之间找到了一个平衡。

npm、yarn 和 cnpm 均提供了很好的依赖管理来帮助我们管理项目中使用到的各种依赖以及版本，但是如果依赖出现了循环调用也就是循环依赖应该怎么解决呢？

## 循环依赖

循环依赖指的是，a 模块的执行依赖 b 模块，而 b 模块的执行又依赖 a 模块。循环依赖可能导致递归加载，处理不好的话可能使得程序无法执行。探讨循环依赖之前，先让我们了解一下 JavaScript 中的模块规范。因为，不同的规范在处理循环依赖时的做法是不同的。

目前，通行的 JavaScript 规范可以分为三种，[CommonJS](<https://link.juejin.cn?target=http%3A%2F%2Fwiki.commonjs.org%2Fwiki%2FModules%2F1.1> "http://wiki.commonjs.org/wiki/Modules/1.1") 、 [AMD](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Famdjs%2Famdjs-api%2Fwiki%2FAMD> "https://github.com/amdjs/amdjs-api/wiki/AMD") 和 [ES6](<https://link.juejin.cn?target=http%3A%2F%2Fwww.ecma-international.org%2Fecma-262%2F6.0%2F> "http://www.ecma-international.org/ecma-262/6.0/")。

### 模块规范

#### CommonJS

从2009年 node.js 出现以来，[CommonJS](<https://link.juejin.cn?target=http%3A%2F%2Fwiki.commonjs.org%2Fwiki%2FModules%2F1.1> "http://wiki.commonjs.org/wiki/Modules/1.1") 模块系统逐渐深入人心。CommonJS 的一个模块就是一个脚本文件，通过 `require` 命令来加载这个模块，并使用模块暴漏出的接口。加载时执行是 CommonJS 模块的重要特性，即脚本代码在 `require` 的时候就会执行模块中的代码。这个特性在服务端是没问题的，但如果引入一个模块就要等待它执行完才能执行后面的代码，这在浏览器端就会有很大的问题了。因此出现了 [AMD](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Famdjs%2Famdjs-api%2Fwiki%2FAMD> "https://github.com/amdjs/amdjs-api/wiki/AMD") 规范，以支持浏览器环境。

#### AMD

[AMD](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Famdjs%2Famdjs-api%2Fwiki%2FAMD> "https://github.com/amdjs/amdjs-api/wiki/AMD") 是 “Asynchronous Module Definition” 的缩写，意思就是“异步模块定义”。它采用异步加载方式加载模块，模块的加载不影响它后面语句的运行。所有依赖这个模块的语句，都定义在一个回调函数中，等到加载完成之后，这个回调函数才会运行。最有代表性的实现则是 [requirejs](<https://link.juejin.cn?target=http%3A%2F%2Frequirejs.org%2F> "http://requirejs.org/")。

#### ES6

不同于 CommonJS 和 AMD 的模块加载方案，[ES6](<https://link.juejin.cn?target=http%3A%2F%2Fwww.ecma-international.org%2Fecma-262%2F6.0%2F> "http://www.ecma-international.org/ecma-262/6.0/") 在 JavaScript 语言层面上实现了模块功能。它的设计思想是，尽量的静态化，使得编译时就能确定模块的依赖关系。在遇到模块加载命令 `import` 时，不会去执行模块，而是只生成一个引用。等到真的需要用到时，再到模块里面去取值。这是和 CommonJS 模块规范的最大不同。

### CommonJS 中循环依赖的解法

请看下面的例子：

`a.js`

    console.log('a starting');
    exports.done = false;
    const b = require('./b.js');
    console.log('in a, b.done = %j', b.done);
    exports.done = true;
    console.log('a done');

`b.js`

    console.log('b starting');
    exports.done = false;
    const a = require('./a.js');
    console.log('in b, a.done = %j', a.done);
    exports.done = true;
    console.log('b done');

`main.js`

    console.log('main starting');
    const a = require('./a.js');
    const b = require('./b.js');
    console.log('in main, a.done=%j, b.done=%j', a.done, b.done);

在这个例子中，a 模块调用 b 模块，b 模块又需要调用 a 模块，这就使得 a 和 b 之间形成了循环依赖，但是当我们执行 `node main.js` 时代码却没有陷入无限循环调用当中，而是输出了如下内容：

    $ node main.js
    main starting
    a starting
    b starting
    in b, a.done = false
    b done
    in a, b.done = true
    a done
    in main, a.done=true, b.done=true

为什么程序没有报错，而是输出如上的内容呢？这是因为 CommonJs 模块的两个特性。第一，加载时执行；第二，已加载的模块会进行缓存，不会重复加载。下面让我们分析下程序的执行过程：

  1. main.js 执行，输出 main starting
  2. main.js 加载 a.js，执行 a.js 并输出 a starting，导出 done = false
  3. a.js 加载 b.js，执行 b.js 并输出 b starting，导出 done = false
  4. b.js 加载 a.js，由于之前 a.js 已加载过一次因此不会重复加载，缓存中 a.js 导出的 done = false，因此，b.js 输出 in b, a.done = false
  5. b.js 导出 done = true，并输出 b done
  6. b.js 执行完毕，执行权交回给 a.js，执行 a.js，并输出 in a, b.done = true
  7. a.js 导出 done = true，并输出 a done
  8. a.js 执行完毕，执行权交回给 main.js，main.js 加载 b.js，由于之前 b.js 已加载过一次，不会重复执行
  9. main.js 输出 in main, a.done=true, b.done=true

从上面的执行过程中，我们可以看到，在 CommonJS 规范中，当遇到 `require()` 语句时，会执行 require 模块中的代码，并缓存执行的结果，当下次再次加载时不会重复执行，而是直接取缓存的结果。正因为此，出现循环依赖时才不会出现无限循环调用的情况。虽然这种模块加载机制可以避免出现循环依赖时报错的情况，但稍不注意就很可能使得代码并不是像我们想象的那样去执行。因此在写代码时还是需要仔细的规划，以保证循环模块的依赖能正确工作（官方原文：Careful planning is required to allow cyclic module dependencies to work correctly within an application）。

除了仔细的规划还有什么办法可以避免出现循环依赖吗？一个不太优雅的方法是在循环依赖的每个模块中先写 exports 语句，再写 require 语句，利用 CommonJS 的缓存机制，在 `require()` 其他模块之前先把自身要导出的内容导出，这样就能保证其他模块在使用时可以取到正确的值。比如：

`A.js`

    exports.done = true;

    let B = require('./B');
    console.log(B.done)

`B.js`

    exports.done = true;

    let A = require('./A');
    console.log(A.done)

这种写法简单明了，缺点是要改变每个模块的写法，而且大部分同学都习惯了在文件开头先写 require 语句。

个人经验来看，在写代码中只要我们注意一下循环依赖的问题就可以了，大部分同学在写 node.js 中应该很少碰到需要手动去处理循环依赖的问题，更甚的是很可能大部分同学都没想过这个问题。

### ES6 中循环依赖的解法

要想知道 ES6 中循环依赖的解法就必须先了解 ES6 的模块加载机制。我们都知道 ES6 使用 `export` 命令来规定模块的对外接口，使用 `import` 命令来加载模块。那么在遇到 import 和 export 时发生了什么呢？ES6 的模块加载机制可以概括为四个字**一静一动** 。

  * 一静：import 静态执行
  * 一动：export 动态绑定

import 静态执行是指，import 命令会被 JavaScript 引擎静态分析，优先于模块内的其他内容执行。  
export 动态绑定是指，export 命令输出的接口，与其对应的值是动态绑定关系，通过该接口可以实时取到模块内部的值。

让我们看下面一个例子：

`foo.js`

    console.log('foo is running');
    import {bar} from './bar'
    console.log('bar = %j', bar);
    setTimeout(() => console.log('bar = %j after 500 ms', bar), 500);
    console.log('foo is finished');

`bar.js`

    console.log('bar is running');
    export let bar = false;
    setTimeout(() => bar = true, 500);
    console.log('bar is finished');

执行 `node foo.js` 时会输出如下内容：

    bar is running
    bar is finished
    foo is running
    bar = false
    foo is finished
    bar = true after 500 ms

是不是和你想的不一样呢？当我们执行 `node foo.js` 时第一行输出的不是 foo.js 的第一个 console 语句，而是先输出了 bar.js 里的 console 语句。这就是因为 import 命令是在编译阶段执行，在代码运行之前先被 JavaScript 引擎静态分析，所以优先于 foo.js 自身内容执行。同时我们也看到 500 毫秒之后也可以取到 bar 更新后的值也说明了 export 命令输出的接口与其对应的值是动态绑定关系。这样的设计使得程序在编译时就能确定模块的依赖关系，这是和 CommonJS 模块规范的最大不同。还有一点需要注意的是，由于 import 是静态执行，所以 import 具有提升效果即 import 命令的位置并不影响程序的输出。

在我们了解了 ES6 的模块加载机制之后来让我们来看一下 ES6 是怎么处理循环依赖的。修改一下上面的例子：

`foo.js`

    console.log('foo is running');
    import {bar} from './bar'
    console.log('bar = %j', bar);
    setTimeout(() => console.log('bar = %j after 500 ms', bar), 500);
    export let foo = false;
    console.log('foo is finished');

`bar.js`

    console.log('bar is running');
    import {foo} from './foo';
    console.log('foo = %j', foo)
    export let bar = false;
    setTimeout(() => bar = true, 500);
    console.log('bar is finished');

执行 `node foo.js` 时会输出如下内容：

    bar is running
    foo = undefined
    bar is finished
    foo is running
    bar = false
    foo is finished
    bar = true after 500 ms

foo.js 和 bar.js 形成了循环依赖，但是程序却没有因陷入循环调用报错而是执行正常，这是为什么呢？还是因为 import 是在编译阶段执行的，这样就使得程序在编译时就能确定模块的依赖关系，一旦发现循环依赖，ES6 本身就不会再去执行依赖的那个模块了，所以程序可以正常结束。这也说明了 ES6 本身就支持循环依赖，保证程序不会因为循环依赖陷入无限调用。虽然如此，但是我们仍然要尽量避免程序中出现循环依赖，因为可能会发生一些让你迷惑的情况。注意到上面的输出，在 bar.js 中输出的 `foo = undefined`，如果没注意到循环依赖会让你觉得明明在 foo.js 中 `export foo = false`，为什么在 bar.js 中却是 `undefined` 呢，这就是循环依赖带来的困惑。在一些复杂大型项目中，你是很难用肉眼发现循环依赖的，而这会给排查异常带来极大的困难。对于使用 webpack 进行项目构建的项目，推荐使用 webpack 插件 [circular-dependency-plugin](<https://link.juejin.cn?target=https%3A%2F%2Fgithub.com%2Faackerman%2Fcircular-dependency-plugin> "https://github.com/aackerman/circular-dependency-plugin") 来帮助你检测项目中存在的所有循环依赖，尽早发现潜在的循环依赖可能会免去未来很大的麻烦。

## 小结

讲了那么多，希望此文能帮助你更好的了解 JavaScript 中的依赖管理，并且处理好项目中的循环依赖问题。
