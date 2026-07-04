from flask import Flask

app = Flask(__name__)
# This creates your Flask application.

@app.route("/")
# This creates a route.
# A route is basically a URL path.
def home():
    return "Hello and Welcome to my first Flask app!!!"
# “When someone visits the homepage /, run the function directly under me.”
# This function runs when someone visits the home page.
# But with Flask, you do not call home() yourself.
# Flask calls it for you when someone visits the matching URL.

@app.route("/about")
def about():
    return "This is the about page."
# This creates another page


if __name__ == "__main__":
    app.run(debug=True)
# So if this file is being called directly then run this
# It means Python has a special built-in variable called: __name__
# When you run the python file directly, python sets it to:
# __name__ = "__main__"
# if __name__ = "__main__" is asking if this is the main file being executed right now
# if it is then run