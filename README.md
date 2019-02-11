Introduction
============

This is an example application that shows how to combine nginx with the
`ngx_aws_auth` and `mod_zip` modules to create a server that can stream
multiple files from Amazon Web Services S3 as a single ZIP file without using
any temporary storage.

For convenience, this project is packaged as a Docker container.

Technologies Used
=================

- Nginx: <https://www.nginx.com>
- Nginx `ngx_aws_auth`: <https://github.com/anomalizer/ngx_aws_auth>
- Nginx `mod_zip`: <https://www.nginx.com/resources/wiki/modules/zip/>

How to use
==========

First we need to build the Docker container:

    docker build -t nginx_s3_streaming_zip .

Get your Amazon Web Services S3 authentication information. Upload some test
files into an S3 bucket. Record their sizes and file names.

We now need to create a file in the format that `mod_zip` understands. For this
example code, we will do this by hand as a static file. In the real world, this
would be created by a dynamic backend (in PHP, Python, etc.).

This is the documentation for the `mod_zip` file format:
- <https://www.nginx.com/resources/wiki/modules/zip/>

Here is an example file in that format. Note that the CRC32 checksum is
optional. **DO NOT FORGET THE `/s3/` PREFIX ON THE FILE NAMES!!!**

    - 1234 /s3/test1.txt test1.txt
    - 5678 /s3/test2.txt test2.txt

Create a new directory `example` and save the file in `example/test.txt`.

Now we run the Docker container on TCP port 8888, and bind mount our example
directory inside the container at `/var/www/html/example/`. We also specify the
Amazon Web Services S3 credentials.

```bash
    docker run -p 8888:80 \
        -v example:/var/www/html/example \
        -e 'AWS_ACCESS_KEY_ID=' \
        -e 'AWS_SECRET_ACCESS_KEY=' \
        -e 'AWS_DEFAULT_REGION=' \
        -e 'AWS_BUCKET=' \
        nginx_s3_streaming_zip
```

And now you can visit the page with cURL (or with the web browser of your choice):

    curl -v -XGET 'http://localhost:8888/example/test.txt' > example.zip

You will have a valid ZIP file containing the files you asked for!

How does it work?
===================
The `nginx.conf` has several configurations.

The main server listening on port `80` directs all the requests depending on:

* All paths matching `^/s3/(?<url>.*)$` (the /s3/ files) will be redirected to the server listening on port `3333`: `http://127.0.0.1:3333/$url`. This server will be our proxy to `S3` files.
* Everything else is handled by the server running on port `8080`: `http://127.0.0.1:8080`.

When the request for `/example/test.txt` arrives, it will be handled by the server running on port `8080`. It will add a header:

    add_header X-Archive-Files 'zip';

which triggers the `mod_zip`. As a result, the content of `example/test.txt` will be parsed by `mod_zip` to generate a zip file on the fly. Now this is where the proxy to `S3` on port `3333` kicks in. Remeber that the `S3` files in `test.txt` had a prefix `/s3/`. This will cause the internal reads to `/s3/test1.txt` to be handled by the proxy and directed to `https://<bucket>.s3.amazonaws.com/test1.txt`.

License Information
===================

This project is licensed under the MIT License. Please see the LICENSE file in
this repository for details.

<https://opensource.org/licenses/MIT>
