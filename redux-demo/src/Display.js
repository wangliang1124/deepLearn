import React from "react";
import store from "./store.js";

class Display extends React.Component {
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

    render() {
        return (
            <div>
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
            </div>
        );
    }
}

export default Display;
