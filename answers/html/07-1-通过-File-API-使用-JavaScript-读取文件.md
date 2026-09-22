# 通过 File API 使用 JavaScript 读取文件

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://web.dev/articles/read-files?hl=zh-cn>
> 对应题目：HTML 第 7 题 · HTML5 File API
> 抓取时间：2026-09-22

---

![](https://web.dev/_static/images/translated.svg?hl=zh-cn) Google 会使用 AI 技术将内容翻译成您偏好的语言。AI 翻译可能包含错误。 

  * [ 首页 ](<https://web.dev/?hl=zh-cn>)
  * [ Articles ](<https://web.dev/articles?hl=zh-cn>)

#  使用 JavaScript 读取文件  使用集合让一切井井有条  根据您的偏好保存内容并对其进行分类。 

![Kayce Basques](https://web.dev/images/authors/kaycebasques.jpg?hl=zh-cn)

Kayce Basques 

[ ](<https://twitter.com/kaycebasques>) [ ](<https://github.com/kaycebasques>)

![Pete LePage](https://web.dev/images/authors/petelepage.jpg?hl=zh-cn)

Pete LePage 

[ ](<https://twitter.com/petele>) [ ](<https://github.com/petele>) [ ](<https://techhub.social/@petele>) [ ](<https://petelepage.com/>)

![Thomas Steiner](https://web.dev/images/authors/thomassteiner.jpg?hl=zh-cn)

Thomas Steiner 

[ ](<https://github.com/tomayac>) [ ](<https://www.linkedin.com/in/thomassteinerlinkedin>) [ ](<https://toot.cafe/@tomayac>) [ ](<https://bsky.app/profile/tomayac.com>) [ ](<https://blog.tomayac.com/>)

选择和互动用户本地设备上的文件是 Web 最常用的功能之一。它允许用户选择文件并将其上传到服务器，例如在分享照片或提交税务文件时。它还允许网站读取和操纵这些数据，而无需通过网络传输数据。本页将逐步介绍如何使用 JavaScript 与文件进行交互。

## 新版 File System Access API

File System Access API 提供了一种从用户本地系统中的文件和目录读取数据以及向其中写入数据的方式。大多数基于 Chromium 的浏览器（例如 Chrome 和 Edge）都支持此功能。如需详细了解，请参阅 [File System Access API](<https://developer.chrome.com/docs/capabilities/web-apis/file-system-access?hl=zh-cn>)。

由于 File System Access API 并非与所有浏览器都兼容，因此我们建议使用 [browser-fs-access](<https://github.com/GoogleChromeLabs/browser-fs-access>)，这是一个辅助库，可在新 API 可用的情况下使用该 API，并在不可用的情况下回退到旧版方法。

## 以传统方式处理文件

本指南介绍了如何使用旧版 JavaScript 方法与文件进行交互。

## 选择文件

选择文件主要有两种方式：使用 [HTML 输入元素](<https://web.dev/articles/read-files#select-input>)和使用[拖放区域](<https://web.dev/articles/read-files#select-dnd>)。

### HTML 输入元素

用户选择文件的最简单方法是使用 [`<input type="file">`](<https://developer.mozilla.org/docs/Web/HTML/Element/input/file>) 元素，该元素在所有主流浏览器中均受支持。点击后，用户可以使用操作系统内置的文件选择界面选择一个文件，如果包含 [`multiple`](<https://developer.mozilla.org/docs/Web/HTML/Element/input/file#Additional_attributes>) 属性，则可以选择多个文件。当用户完成文件选择后，元素的 `change` 事件会触发。您可以从 `event.target.files`（即 [`FileList`](<https://developer.mozilla.org/docs/Web/API/FileList>) 对象）访问文件列表。`FileList` 中的每个项都是一个 [`File`](<https://developer.mozilla.org/docs/Web/API/File>) 对象。

    <!-- The `multiple` attribute lets users select multiple files. -->
    <input type="file" id="file-selector" multiple>
    <script>
      const fileSelector = document.getElementById('file-selector');
      fileSelector.addEventListener('change', (event) => {
        const fileList = event.target.files;
        console.log(fileList);
      });
    </script>

**注意** ： 请检查 [`window.showOpenFilePicker()`](<https://developer.chrome.com/articles/file-system-access/?hl=zh-cn#ask-the-user-to-pick-a-file-to-read>) 方法是否是您用例的可行替代方案。它提供了一个文件句柄，因此您除了读取文件之外，还可以将内容写回文件。此方法可以进行 [polyfill](<https://github.com/GoogleChromeLabs/browser-fs-access#opening-files>)。

以下示例让用户可以使用其操作系统的内置文件选择界面选择多个文件，然后将每个所选文件记录到控制台。

#### 限制用户可以选择的文件类型

在某些情况下，您可能需要限制用户可以选择的文件类型。例如，图片编辑应用应仅接受图片，而不接受文本文件。如需设置文件类型限制，请向输入元素添加 [`accept`](<https://developer.mozilla.org/docs/Web/HTML/Element/input/file#Additional_attributes>) 属性，以指定接受哪些文件类型：

    <input type="file" id="file-selector" accept=".jpg, .jpeg, .png">

### 自定义拖放

在某些浏览器中，`<input type="file">` 元素也是放置目标，允许用户将文件拖放到您的应用中。不过，此放置目标较小，可能难以使用。不过，在使用 `<input type="file">` 元素提供核心功能后，您可以提供一个大型自定义拖放界面。

**注意** ： 请检查 [`DataTransferItem.getAsFileSystemHandle()`](<https://developer.chrome.com/articles/file-system-access/?hl=zh-cn#drag-and-drop-integration>) 方法是否是您用例的可行替代方案。它提供了一个文件句柄，让您除了读取文件之外，还可以将内容写回文件。

#### 选择降落区

放置表面取决于应用的设计。您可能只希望窗口的一部分成为放置区，但也可以使用整个窗口。

![图片压缩 Web 应用 Squoosh 的屏幕截图。](https://web.dev/static/articles/read-files/image/a-screenshot-squoosh-i-9973c866302e4.png?hl=zh-cn) Squoosh 会将整个窗口变成放置区。 

图片压缩应用 Squoosh 可让用户将图片拖动到窗口中的任意位置，并点击**选择图片** 来调用 `<input type="file">` 元素。无论您选择哪个区域作为放置区，都应确保用户清楚知道他们可以将文件拖放到该区域。

#### 定义放置区

如需将元素设为拖放区域，请为以下两个事件创建监听器：[`dragover`](<https://developer.mozilla.org/docs/Web/API/Document/dragover_event>) 和 [`drop`](<https://developer.mozilla.org/docs/Web/API/Document/drop_event>)。`dragover` 事件会更新浏览器界面，以直观地表明拖放操作正在创建文件副本。用户将文件放到表面上后，系统会触发 `drop` 事件。与输入元素一样，您可以从 `event.dataTransfer.files`（即 [`FileList`](<https://developer.mozilla.org/docs/Web/API/FileList>) 对象）访问文件列表。`FileList` 中的每个项都是一个 [`File`](<https://developer.mozilla.org/docs/Web/API/File>) 对象。

    const dropArea = document.getElementById('drop-area');

    dropArea.addEventListener('dragover', (event) => {
      event.stopPropagation();
      event.preventDefault();
      // Style the drag-and-drop as a "copy file" operation.
      event.dataTransfer.dropEffect = 'copy';
    });

    dropArea.addEventListener('drop', (event) => {
      event.stopPropagation();
      event.preventDefault();
      const fileList = event.dataTransfer.files;
      console.log(fileList);
    });

[`event.stopPropagation()`](<https://developer.mozilla.org/docs/Web/API/Event/stopPropagation>) 和 [`event.preventDefault()`](<https://developer.mozilla.org/docs/Web/API/Event/preventDefault>) 会停止浏览器的默认行为，并让您的代码运行。如果没有这些事件，浏览器会离开您的网页，并打开用户拖放到浏览器窗口中的文件。

如需查看实时演示，请参阅[自定义拖放](<https://googlechrome.github.io/samples/custom-drag-and-drop/>)。

### 目录呢？

遗憾的是，目前还没有使用 JavaScript 访问目录的好方法。

`<input type="file">` 元素上的 [`webkitdirectory`](<https://developer.mozilla.org/docs/Web/API/HTMLInputElement/webkitdirectory>) 属性可让用户选择一个或多个目录。[大多数主流浏览器都支持](<https://caniuse.com/#search=webkitdirectory>)，但 Android 版 Firefox 和 iOS 版 Safari 除外。

**注意** ： 请检查 [`window.showDirectoryPicker()`](<https://developer.chrome.com/articles/file-system-access/?hl=zh-cn#opening-a-directory-and-enumerating-its-contents>) 方法是否是您用例的可行替代方案。它提供了一个目录句柄，因此您除了读取之外，还可以写回目录。此方法可以进行 [polyfill](<https://github.com/GoogleChromeLabs/browser-fs-access#opening-directories>)。

如果启用了拖放功能，用户可能会尝试将目录拖到放置区。当放置事件触发时，它会包含目录的 `File` 对象，但不会提供对目录中任何文件的访问权限。

## 读取文件元数据

[`File`](<https://developer.mozilla.org/docs/Web/API/File>) 对象包含有关文件的元数据。大多数浏览器都会提供文件名、文件大小和 MIME 类型，不过根据平台的不同，不同的浏览器可能会提供不同的信息或额外的信息。

    function getMetadataForFileList(fileList) {
      for (const file of fileList) {
        // Not supported in Safari for iOS.
        const name = file.name ? file.name : 'NOT SUPPORTED';
        // Not supported in Firefox for Android or Opera for Android.
        const type = file.type ? file.type : 'NOT SUPPORTED';
        // Unknown cross-browser support.
        const size = file.size ? file.size : 'NOT SUPPORTED';
        console.log({file, name, type, size});
      }
    }

您可以在 [`input-type-file`](<https://googlechrome.github.io/samples/input-type-file/>) 演示中查看此功能的实际效果。

## 读取文件内容

使用 [`FileReader`](<https://developer.mozilla.org/docs/Web/API/FileReader>) 将 `File` 对象的内容读入内存。您可以告知 `FileReader` 将文件读取为[数组缓冲区](<https://developer.mozilla.org/docs/Web/API/FileReader/readAsArrayBuffer>)、[数据网址](<https://developer.mozilla.org/docs/Web/API/FileReader/readAsDataURL>)或[文本](<https://developer.mozilla.org/docs/Web/API/FileReader/readAsText>)：

    function readImage(file) {
      // Check if the file is an image.
      if (file.type && !file.type.startsWith('image/')) {
        console.log('File is not an image.', file.type, file);
        return;
      }

      const reader = new FileReader();
      reader.addEventListener('load', (event) => {
        img.src = event.target.result;
      });
      reader.readAsDataURL(file);
    }

此示例读取用户提供的 `File`，然后将其转换为数据网址，并使用该数据网址在 `img` 元素中显示图片。如需了解如何验证用户是否已选择图片文件，请参阅 [`read-image-file`](<https://googlechrome.github.io/samples/read-an-image-file/>) 演示。

### 监控文件读取的进度

读取大型文件时，提供一些用户体验来告知用户读取进度会很有帮助。为此，请使用 `FileReader` 提供的 [`progress`](<https://developer.mozilla.org/docs/Web/API/FileReader/progress_event>) 事件。`progress` 事件具有两个属性：`loaded`（已读取的量）和 `total`（要读取的量）。

    function readFile(file) {
      const reader = new FileReader();
      reader.addEventListener('load', (event) => {
        const result = event.target.result;
        // Do something with result
      });

      reader.addEventListener('progress', (event) => {
        if (event.loaded && event.total) {
          const percent = (event.loaded / event.total) * 100;
          console.log(`Progress: ${Math.round(percent)}`);
        }
      });
      reader.readAsDataURL(file);
    }

如未另行说明，那么本页面中的内容已根据[知识共享署名 4.0 许可](<https://creativecommons.org/licenses/by/4.0/>)获得了许可，并且代码示例已根据 [Apache 2.0 许可](<https://www.apache.org/licenses/LICENSE-2.0>)获得了许可。有关详情，请参阅 [Google 开发者网站政策](<https://developers.google.com/site-policies?hl=zh-cn>)。Java 是 Oracle 和/或其关联公司的注册商标。

最后更新时间 (UTC)：2010-06-18。

[[["易于理解","easyToUnderstand","thumb-up"],["解决了我的问题","solvedMyProblem","thumb-up"],["其他","otherUp","thumb-up"]],[["没有我需要的信息","missingTheInformationINeed","thumb-down"],["太复杂/步骤太多","tooComplicatedTooManySteps","thumb-down"],["内容需要更新","outOfDate","thumb-down"],["翻译问题","translationIssue","thumb-down"],["示例/代码问题","samplesCodeIssue","thumb-down"],["其他","otherDown","thumb-down"]],["最后更新时间 (UTC)：2010-06-18。"],[],[]]
