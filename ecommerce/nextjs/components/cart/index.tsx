import CartModal from './modal';

export default function Cart() {
    // const cartId = cookies().get('cartId')?.value;
    let cart;

    // if (cartId) {
    //     cart = await getCart(cartId);
    // }

    return <CartModal cart={cart} />;
}
