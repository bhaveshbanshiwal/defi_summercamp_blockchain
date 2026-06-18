from flask import Flask, render_template, jsonify

app = Flask(__name__)



@app.route('/')
def index():
    return render_template('index.html', 
        your_token_address="0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0",
        vendor_address="0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82",
        balloons_address="0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
        dex_address="0x5FC8d32690cc91D4c39d9d3abcBD16989F875707"
    )

@app.route('/health')
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
