import React from "react";
import logo from "./logo.svg";
import "./App.css";
import store from "./store.js";
import { addToCart, updateCart, deleteFromCart } from "./actions/cart";

class App extends React.Component {
    state = {
        cart: [],
    };

    componentDidMount() {
        this.setState({
            cart: store.getState().shoppingCart.cart,
        });
        this.unsubscribe = store.subscribe(() => {
            console.log(store.getState());
            this.setState({
                cart: store.getState().shoppingCart.cart,
            });
        });
    }

    componentWillUnmount() {
        this.unsubscribe();
    }

    handleAdd = () => {
        store.dispatch(addToCart("Coffee 500gm", 1, 250));
        // store.dispatch(addToCart("Flour 1kg", 2, 110));
        // store.dispatch(addToCart("Juice 2L", 1, 250));
    };

    handleDelete = () => {
        store.dispatch(deleteFromCart("Coffee 500gm"));
    };

    handleUpdate = () => {
        store.dispatch(updateCart("Coffee 500gm", 99, 9999));
    };

    render() {
        console.log("initial state: ", store.getState());

        return (
            <div className="App">
                <header className="App-header">
                    <img src={logo} className="App-logo" alt="logo" />
                    {this.state.cart.map((item, index) => {
                        return (
                            <ul key={index}>
                                <li>
                                    <span>{item.product}</span>
                                    <span>{item.quantity}</span>
                                    <span>{item.unitCost}</span>
                                </li>
                            </ul>
                        );
                    })}
                    <button onClick={this.handleAdd}>加入购入车</button>
                    <button onClick={this.handleDelete}>删除</button>
                    <button onClick={this.handleUpdate}>更新</button>
                </header>
            </div>
        );
    }
}

export default App;
