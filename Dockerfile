FROM testbed/vim:latest

RUN install_vim -tag neovim:v0.2.0 -build

ENV GH_USER user
ENV GH_PASS pass

RUN apk --no-cache add bash python3 git curl && \
	pip3 install --upgrade pip

COPY ./entrypoint.sh /entrypoint.sh
ENV PATH=$PATH:/vim-build/bin

RUN git clone https://github.com/junegunn/vader.vim.git vader

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /testplugin

CMD ["neovim-v0.2.0", "-u", "test/fixtures/vimrc", "-c", "Vader! test/*"]
