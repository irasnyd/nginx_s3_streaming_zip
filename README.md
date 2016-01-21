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

Now we run the Docker container on TCP port 8888, and bind mount our example
file inside the container at `/var/www/html/example.txt`. We also specify the
Amazon Web Services S3 credentials.

    docker run -p 8888:80 \
        -v example:/var/www/html/example \
        -e 'AWS_ACCESS_KEY_ID=" \
        -e 'AWS_SECRET_ACCESS_KEY=" \
        -e 'AWS_DEFAULT_REGION=" \
        -e 'AWS_BUCKET=" \
        nginx_s3_streaming_zip

And now you can visit the page with cURL (or with the web browser of your choice):

    curl -v -XGET 'http://localhost:8888/example' > example.zip

You will have a valid ZIP file containing the files you asked for!

License Information
===================

This project is licensed under the MIT License. Please see the LICENSE file in
this repository for details.

<https://opensource.org/licenses/MIT>
