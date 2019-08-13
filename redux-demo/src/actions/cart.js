export const ADD_TO_CART = "ADD_TO_CART";
export const UPDATE_CART = "UPDATE_CART";
export const DELETE_FROM_CART = "DELETE_FROM_CART";

export function addToCart(product, quantity, unitCost) {
    console.log('==== add ====')

    return {
        type: ADD_TO_CART,
        payload: { product, quantity, unitCost },
    };
}

export function updateCart(product, quantity, unitCost) {
    console.log('====update====')
    return {
        type: UPDATE_CART,
        payload: {
            product,
            quantity,
            unitCost,
        },
    };
}

export function deleteFromCart(product) {
    console.log('==== delete ====')

    return {
        type: DELETE_FROM_CART,
        payload: {
            product,
        },
    };
}
