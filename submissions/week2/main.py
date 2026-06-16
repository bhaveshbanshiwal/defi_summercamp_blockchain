import asyncio
import websockets
import json

async def listen_orderbook():
    uri = "wss://stream.binance.com:9443/ws/ethusdt@depth"
    async with websockets.connect(uri) as websocket:
        print("Connected to WebSocket orderbook!")
        while True:
            message = await websocket.recv()
            data = json.loads(message)
            # Print the first ask and bid
            if 'a' in data and 'b' in data and len(data['a']) > 0 and len(data['b']) > 0:
                best_ask = data['a'][0]
                best_bid = data['b'][0]
                print(f"ETH/USDT -> Best Bid: {best_bid[0]} (Qty: {best_bid[1]}) | Best Ask: {best_ask[0]} (Qty: {best_ask[1]})")

if __name__ == "__main__":
    try:
        asyncio.run(listen_orderbook())
    except KeyboardInterrupt:
        print("\nOrderbook stream stopped.")
