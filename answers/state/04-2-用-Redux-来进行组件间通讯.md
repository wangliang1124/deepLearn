# 用 Redux 来进行组件间通讯

> 📦 **本地存档** —— 正文抓取自原文，仅供离线阅读，版权归原作者。
> 原文：<https://segmentfault.com/a/1190000008411613>
> 对应题目：状态管理 第 4 题 · Redux 如何实现多个组件之间的通信，多个组件使用相同状态如何进行管理
> 抓取时间：2026-09-22

---

## 用Redux来进行组件间通讯

[demo地址](<https://link.segmentfault.com/?enc=cVumS4PLfZ%2BM6W87n1H%2FDw%3D%3D.FUxQ0swwFRQGu5C5OBkj0SSivB2pdF0iYzj554PbsTvWopPnGhJ3ycitv4GgJYX67g7RmxFpPm2RroscJiTGpg%3D%3D>)

### 疑惑

之前在做项目的时候，一直会遇到一个困扰我的问题，两个互相独立的子组件如何通讯？

假设现在结构如下

![clipboard.png](https://segmentfault.com/img/bVHLza?w=872&h=583)

`ListItem`是一个todoList组件，里面有一个`删除操作`，点击添加备注时会弹出模态框，让用户进行填写。

![clipboard.png](https://segmentfault.com/img/bVJsim?w=692&h=786)

按照以前的写法，要像这样

![clipboard.png](https://segmentfault.com/img/bVHLE0?w=1302&h=499)

  1. 父组件要传递一个props:`showDelModal`,以便于`todoItem`调起模态框。

  2. 同时，父组件要传递`confirm`、`cancel`两个props给`Modal`组件,用于接收`Modal`组件点击了确认还是取消。

假设这样的子组件较多，那父组件就显得很臃肿，阅读代码也很麻烦，我希望调用确认模态框时就像调用`window.confirm`一样，逻辑清晰，不需要这么多的回调函数。

### 实现

用了redux后，发现我的思路是可以被实现的，下面讲一下过程，建议和[代码](<https://link.segmentfault.com/?enc=tXVzIzVG01dSOfwt33CMmQ%3D%3D.NkXPx7N9HqlWjbNSZQeoPfJLtOVcEaRwaxPAA3oNBdHmwlYKdNEe0ZKlr7VPzGL6mMnLW6Vo8HeBABVUxYfRQA%3D%3D>)一起看。

我们新建一个modal组件

    import React from 'react';
    import ReactDOM from 'react-dom';
    import '../stylus/modal.styl';

    export default class ConfirmModal extends React.Component {
        constructor() {
            super();
        }

        componentDidMount() {

        }

        onConfirm() {

            this.props.resolve(true);
        }

        onCancel() {
            this.props.reject(false);

        }

        render() {
            return (
                <div className="modal" style={{display: this.props.show ? 'block' : 'none'}}>
                    <div className="modal-inner">
                        <h3>确认删除？</h3>
                        <div className="btn-action">
                            <button className="pure-button" onClick={this.onConfirm.bind(this)}>确认</button>
                            <button className="pure-button" onClick={this.onCancel.bind(this)}>取消</button>
                        </div>
                    </div>
                </div>
            )
        }

    }

修改原有todoItem的del函数

        //重点在这
        waitForConfirm() {

            let {store} = this.context;

            return new Promise((resolve, reject) => {

                store.dispatch({
                    type: 'SHOW_MODAL',
                    payload: {
                        show: true,
                        resolve,
                        reject
                    }
                })

            });
        }

        closeModal() {
            let {store} = this.context;

            store.dispatch({
                type: 'CLOSE_MODAL',
                payload: {}
            })

        }

        async del() {
            let {index} = this.props;

            let ret = await this.waitForConfirm().catch(e => {
                return false;
            });

            if (!ret) {
                this.closeModal();
                return false;
            }

            this.props.handleDelTodo(index);

            this.closeModal();

        }

原有的reducer上增加数据

    /**
     * Created by chenchen on 2017/2/4.
     */

    import {combineReducers} from 'redux';

    function todoList(todolist = [], action) {
        switch (action.type) {
            case 'ADD_TODO':
                return [...todolist, ...action.payload];
                return todolist;
            case 'DEL_TODO':
                return todolist.filter((val, index) => index !== action.payload);
            default:
                return todolist;
        }

    }

    //确认删除模态框
    function confirmModalData(data = {
        show: false,
        resolve: null,
        reject: null
    }, action) {
        let d = {};
        switch (action.type) {
            case 'SHOW_MODAL':
                return Object.assign(d, data, action.payload);
            case 'CLOSE_MODAL':
                return Object.assign(d, data, {show: false});
            default:
                return data;
        }
    }

    //... 其他reducer

    export default combineReducers({todoList, confirmModalData});

下面这种写法，是不是就很像`window.confirm`呢？

    let ret = await this.waitForConfirm().catch(e => {
                return false;
            });

### 原理

其实原理还是用了回调函数，只是将其包裹在一个Promise对象中：  
把Modal的`confirm`和`cancel`放入Redux的store中，每个todoItem进行删除操作时，会替换store中的`resolve`和`reject`函数，并返回一个Promise对象，而Modal进行确认和取消操作，会调用store中的`resolve`和`reject`函数，这样，todoItem等待模态框的Promise就返回啦，通过返回值就可以判断是确认和取消操作了。

这样的好处就是，即使组件的层级再深，也不会增加数据传递的复杂度，因为两者是直接通过store来通讯的。
