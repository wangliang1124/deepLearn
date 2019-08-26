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
                <table style={{width: 600}}>
                    <tbody>
                        <tr>
                            <td>产品</td>
                            <td>数量</td>
                            <td>价格</td>
                        </tr>
                        {this.state.cart.map((item, index) => {
                            return (
                                <tr key={index}>
                                    <td>{item.product}</td>
                                    <td>{item.quantity}</td>
                                    <td>{item.unitCost}</td>
                                </tr>
                            );
                        })}
                    </tbody>
                </table>
            </div>
        );
    }
}

export default Display;
