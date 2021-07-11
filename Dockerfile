FROM ubuntu:focal

ENV GH_USER user
ENV GH_PASS pass

RUN apt-get update && \
	apt-get install neovim curl git python3-pip -y && \
	rm -rf /var/lib/apt/lists/* 

COPY ./entrypoint.sh /entrypoint.sh
ENV PATH=$PATH:/vim-build/bin

RUN git clone https://github.com/junegunn/vader.vim.git vader

ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /testplugin

CMD ["nvim", "-u", "test/fixtures/vimrc", "-c", "Vader! test/*"]
