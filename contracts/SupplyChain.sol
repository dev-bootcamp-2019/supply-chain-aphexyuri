/*
	This exercise has been updated to use Solidity version 0.5
	Breaking changes from 0.4 to 0.5 can be found here: 
	https://solidity.readthedocs.io/en/v0.5.0/050-breaking-changes.html
*/

pragma solidity ^0.5.0;

contract SupplyChain {
	/// contract owner
	address owner;

	/// most recent sku
	uint skuCount;

	/// public mappint of skus to items
  	mapping (uint => Item) public items;
	
	/// item states
	enum State { ForSale, Sold, Shipped, Received }

	/// struct declaration of items
	struct Item {
		string name;
		uint sku;
		uint price;
		State state;
		address payable seller;
		address payable buyer;
	}

	/// item state transition events
	event ForSale(uint sku);
	event Sold(uint sku);
	event Shipped(uint sku);
	event Received(uint sku);

	/// ensures sender is contract owner
	modifier isOwner() { require(msg.sender == owner); _; }
	
	/// verify a sender
	modifier verifyCaller (address _address) { require (msg.sender == _address); _; }

	/// ensure sufficient wei sent with transaction
	modifier paidEnough(uint _price) { require(msg.value >= _price); _; }
	modifier checkValue(uint _sku) {
		//refund them after pay for item (why it is before, _ checks for logic before func)
		_;
		uint _price = items[_sku].price;
		uint amountToRefund = msg.value - _price;
		items[_sku].buyer.transfer(amountToRefund);
  	}

	/// ensure an item is for sale
	modifier forSale(uint sku) { require(items[sku].state == State.ForSale); _; }

	/// ensure an item has been sold
	modifier sold(uint sku) { require(items[sku].state == State.Sold); _; }

	/// ensure an item has shipped
	modifier shipped(uint sku) { require(items[sku].state == State.Shipped); _; }

	/// ensure an item has been received
	modifier received(uint sku) { require(items[sku].state == State.Received); _; }

	constructor()
		public
	{
		owner = msg.sender; 
		skuCount = 0;
	}

	/// adds a new item for sale
	function addItem(string memory _name, uint _price)
		public
		returns(bool)
	{
		emit ForSale(skuCount);
		items[skuCount] = Item({name: _name, sku: skuCount, price: _price, state: State.ForSale, seller: msg.sender, buyer: address(0)});
		skuCount = skuCount + 1;
		return true;
	}

	/// purchase an item
	function buyItem(uint sku)
		public
		payable
		forSale(sku)
		paidEnough(sku)
		checkValue(sku)
	{
		// transfer money to seller
		items[sku].seller.transfer(items[sku].price);

		// set buyer as person who called transaction
		items[sku].buyer = msg.sender;

		// set state to sold
		items[sku].state = State.Sold;

		// log event
		emit Sold(sku);
	}

	/// mark item as shipped
	function shipItem(uint sku)
		public
		sold(sku)
		verifyCaller(items[sku].seller)
	{
		items[sku].state = State.Shipped;
		emit Shipped(sku);
	}

	/// mark item as received
	function receiveItem(uint sku)
		public
		shipped(sku)
		verifyCaller(items[sku].buyer)
	{
		items[sku].state = State.Received;
		emit Received(sku);
	}

	/* We have these functions completed so we can run tests, just ignore it :) */
	function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
	{
		name = items[_sku].name;
		sku = items[_sku].sku;
		price = items[_sku].price;
		state = uint(items[_sku].state);
		seller = items[_sku].seller;
		buyer = items[_sku].buyer;
		return (name, sku, price, state, seller, buyer);
	}
}
