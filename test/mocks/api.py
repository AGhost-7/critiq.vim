#!/usr/bin/env python3

from flask import Flask, jsonify, request
from os import path
from functools import wraps

app = Flask('http_mock')


def auth(function):
    @wraps(function)
    def wrap(*args, **kwargs):
        if 'Authorization' not in request.headers:
            response = jsonify({'message': 'Missing authorization header'})
            response.status_code = 401
            return response

        return function(*args, **kwargs)
    return wrap


def fixture(file_name):
    base_path = path.dirname(path.realpath(__file__))
    file_path = path.join(base_path, '../fixtures', file_name)
    file = open(file_path, 'r')
    contents = file.read()
    file.close()
    return contents


@app.route('/')
def hello():
    return jsonify({'message': 'hello world!'})


@app.route('/repos/AGhost-7/critiq.vim/pulls/1')
@auth
def list_prs():
    if(request.headers['Accept'] == 'application/vnd.github.v3.diff'):
        return 'hello diff\n'
    return fixture('pr_1.json')


@app.route('/search/issues')
@auth
def search_issues():
    return fixture('issues_open.json')


@app.route('/repos/AGhost-7/critiq.vim/pulls/1/reviews', methods=['GET'])
@auth
def list_reviews():
    return fixture('reviews_pr_1.json')


@app.route('/repos/AGhost-7/critiq.vim/pulls/1/reviews', methods=['POST'])
@auth
def create_review():
    return jsonify(request.get_json(force=True))


@app.route('/repos/AGhost-7/critiq.vim/pulls/1/comments', methods=['GET'])
@auth
def list_comments():
    return fixture('pr_comments.json')


@app.route('/repos/AGhost-7/critiq.vim/pulls/1/comments', methods=['POST'])
@auth
def create_comment():
    return jsonify(request.get_json(force=True))


@app.route('/repos/AGhost-7/critiq.vim/pulls/1/merge', methods=['PUT'])
@auth
def merge_pr():
    return jsonify({})


@app.route('/repos/AGhost-7/critiq.vim/labels', methods=['GET'])
@auth
def pr_labels():
    return fixture('repo_labels.json')


@app.route('/authorizations', methods=['POST'])
@auth
def create_authorization():
    return jsonify({'token': 'foobar'})


app.run(debug=True)
