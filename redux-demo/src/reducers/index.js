import { combineReducers } from 'redux';
import productsReducer from './products';
import cartReducer from './cart';

const allReducers = {
  products: productsReducer,
  shoppingCart: cartReducer
}

const rootReducer = combineReducers(allReducers);

export default rootReducer;