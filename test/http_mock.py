#!/usr/bin/env python3

from flask import Flask, jsonify, request
from os import path

app = Flask('http_mock')


def fixture(file_name):
    base_path = path.dirname(path.realpath(__file__))
    file_path = path.join(base_path, 'fixtures', file_name)
    file = open(file_path, 'r')
    contents = file.read()
    file.close()
    return contents


@app.route('/')
def hello():
    return jsonify({'message': 'hello world!'})


@app.route('/repos/AGhost-7/critiq.vim/pulls')
def list_prs():
    if(request.headers['Accept'] == 'application/vnd.github.v3.diff'):
        return 'hello diff'
    return fixture('prs_open.json')


@app.route('/repos/AGhost-7/critiq.vim/pulls/1/reviews')
def list_reviews():
    return fixture('reviews_pr_1.json')


app.run(debug=True)
