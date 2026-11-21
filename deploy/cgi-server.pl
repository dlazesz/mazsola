#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket::INET;
use File::Temp qw(tempfile);
use Cwd qw(abs_path);
use File::Basename qw(basename);

# --------------------------------------------------
# Configuration
# --------------------------------------------------

my $PORT  = 8080;
my $HOST  = '0.0.0.0';
my $DEBUG = 1;

my $ROOT = abs_path('www');

die "ERROR: www directory not found!\n" unless $ROOT && -d $ROOT;

my $MAX_BODY = 10_000_000;

# --------------------------------------------------
# HTTP server
# --------------------------------------------------

my $server = IO::Socket::INET->new(
    LocalAddr => $HOST,
    LocalPort => $PORT,
    Listen    => 10,
    Reuse     => 1,
) or die "Cannot start server: $!\n";

# --------------------------------------------------
# Graceful shutdown
# --------------------------------------------------

$SIG{INT} = sub {
    print STDERR "\nSIGINT received. Shutting down...\n";
    close($server);
    exit(0);
};

$SIG{TERM} = sub {
    print STDERR "\nSIGTERM received. Shutting down...\n";
    close($server);
    exit(0);
};


$SIG{CHLD} = 'DEFAULT';

print "\n";
print "----------------------------------\n";
print " Perl CGI Development Server\n";
print "----------------------------------\n";
print " URL:   http://localhost:$PORT/\n";
print " ROOT:  $ROOT\n";
print " DEBUG: $DEBUG\n";
print "----------------------------------\n\n";

while (my $client = $server->accept()) {

    binmode($client);

    eval {
        handle_request($client);
    };

    if ($@) {
        print STDERR "SERVER ERROR: $@\n";

        eval {
            send_response(
                $client,
                '500 Internal Server Error',
                'text/plain; charset=utf-8',
                'Internal server error'
            );
        };
    }

    close($client);
}

# --------------------------------------------------
# HTTP response
# --------------------------------------------------

sub send_response {

    my ($client, $status, $type, $body, $method) = @_;

    $body //= '';

    my $length = length($body);

    my $header =
        "HTTP/1.1 $status\r\n" .
        "Content-Type: $type\r\n" .
        "Content-Length: $length\r\n" .
        "Connection: close\r\n" .
        "X-Content-Type-Options: nosniff\r\n" .
        "\r\n";

    print $client $header;

    print $client $body unless defined($method) && $method eq 'HEAD';
}

# --------------------------------------------------
# URL decoding
# --------------------------------------------------

sub url_decode {

    my ($value) = @_;

    $value //= '';

    $value =~ tr/+/ /;

    $value =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;

    return $value;
}

# --------------------------------------------------
# HTML escaping
# --------------------------------------------------

sub html_escape {

    my ($value) = @_;

    $value //= '';

    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/"/&quot;/g;
    $value =~ s/'/&#39;/g;

    return $value;
}

# --------------------------------------------------
# HTTP request handler
# --------------------------------------------------

sub handle_request {

    my ($client) = @_;

    my $request = <$client>;

    return unless defined $request;

    my ($method, $uri, $protocol) =
        $request =~ /^(\S+)\s+(\S+)\s+(HTTP\/\d\.\d)/;

    unless ($method && $uri) {

        send_response(
            $client,
            '400 Bad Request',
            'text/plain',
            'Bad request'
        );

        return;
    }

    unless ($method =~ /^(GET|POST|HEAD)$/) {

        send_response(
            $client,
            '405 Method Not Allowed',
            'text/plain',
            'Method not allowed'
        );

        return;
    }

    # ----------------------------------------------
    # Read HTTP headers
    # ----------------------------------------------

    my %headers;

    my $header_size = 0;

    while (my $line = <$client>) {

        $header_size += length($line);

        if ($header_size > 65536) {

            send_response(
                $client,
                '431 Request Header Fields Too Large',
                'text/plain',
                'Headers too large'
            );

            return;
        }

        last if $line =~ /^\r?\n$/;

        my ($key, $value) =
            $line =~ /^([^:\s]+):\s*(.*?)\s*$/;

        if (defined $key) {

            $key = lc($key);

            $headers{$key} = defined $headers{$key}
                ? "$headers{$key}, $value"
                : $value;
        }
    }

    if (($headers{'transfer-encoding'} // '') =~ /chunked/i) {

        send_response(
            $client,
            '501 Not Implemented',
            'text/plain',
            'Chunked transfer encoding is not supported'
        );

        return;
    }

    # ----------------------------------------------
    # Parse URL
    # ----------------------------------------------

    my ($path, $query) = split(/\?/, $uri, 2);

    $query //= '';

    $path = url_decode($path);

    if ($path =~ /[\x00-\x1f\x7f\\]/ ||
        $path =~ /(?:^|\/)\.\.(?:\/|$)/) {

        send_response(
            $client,
            '403 Forbidden',
            'text/plain',
            'Forbidden'
        );

        return;
    }

    # ----------------------------------------------
    # Directory handling
    # ----------------------------------------------

    $path = '/index.html' if $path eq '/';

    my $requested_path = "$ROOT$path";

    my $directory = abs_path($requested_path);

    if (
        defined $directory &&
        (
            $directory eq $ROOT ||
            index($directory, "$ROOT/") == 0
        ) &&
        -d $directory
    ) {

        # Redirect /directory to /directory/

        unless ($path =~ /\/$/) {

            my $location = $path . '/';

            $location .= "?$query" if $query ne '';

            print $client
                "HTTP/1.1 301 Moved Permanently\r\n",
                "Location: $location\r\n",
                "Content-Length: 0\r\n",
                "Connection: close\r\n",
                "\r\n";

            return;
        }

        # Directory requested -> index.html

        $path .= 'index.html';
    }

    # ----------------------------------------------
    # Locate requested file
    # ----------------------------------------------

    my $file = abs_path("$ROOT$path");

    unless (
        defined $file &&
        (
            $file eq $ROOT ||
            index($file, "$ROOT/") == 0
        ) &&
        -f $file
    ) {

        send_response(
            $client,
            '404 Not Found',
            'text/plain',
            'File not found'
        );

        return;
    }

    # ----------------------------------------------
    # Read POST body
    # ----------------------------------------------

    my $body = '';

    if ($method eq 'POST') {

        my $length = $headers{'content-length'} // '';

        unless ($length =~ /^\d+$/ && $length <= $MAX_BODY) {

            send_response(
                $client,
                '413 Content Too Large',
                'text/plain',
                'Invalid or excessive request body'
            );

            return;
        }

        while (length($body) < $length) {

            my $n = read(
                $client,
                my $chunk,
                $length - length($body)
            );

            last unless $n;

            $body .= $chunk;
        }

        if (length($body) != $length) {

            send_response(
                $client,
                '400 Bad Request',
                'text/plain',
                'Incomplete request body'
            );

            return;
        }
    }

    # ----------------------------------------------
    # Execute CGI or serve static file
    # ----------------------------------------------

    if ($file =~ /\.pl$/i) {

        run_cgi(
            $client,
            $file,
            $method,
            $query,
            \%headers,
            $body,
            $path
        );

    } else {

        serve_static(
            $client,
            $file,
            $method
        );
    }
}

# --------------------------------------------------
# CGI execution
# --------------------------------------------------

sub run_cgi {

    my ($client, $script, $method, $query, $headers, $body, $url_path) = @_;

    # ----------------------------------------------
    # Temporary files
    # ----------------------------------------------

    my ($in_fh, $in_file) = tempfile();

    binmode($in_fh);

    print $in_fh $body;

    close($in_fh);

    my ($out_fh, $out_file) = tempfile();

    close($out_fh);

    my ($err_fh, $err_file) = tempfile();

    close($err_fh);

    # ----------------------------------------------
    # Start CGI process
    # ----------------------------------------------

    my $pid = fork();

    unless (defined $pid) {

        unlink($in_file, $out_file, $err_file);

        send_response(
            $client,
            '500 Internal Server Error',
            'text/plain',
            'Fork failed'
        );

        return;
    }

    if ($pid == 0) {

        # Child process

        open(STDIN, '<', $in_file) or die $!;

        open(STDOUT, '>', $out_file) or die $!;

        open(STDERR, '>', $err_file) or die $!;

        my %env = (

            GATEWAY_INTERFACE => 'CGI/1.1',

            SERVER_SOFTWARE => 'Perl Development Server',

            SERVER_NAME => 'localhost',

            SERVER_PORT => $PORT,

            SERVER_PROTOCOL => 'HTTP/1.1',

            REQUEST_METHOD => $method,

            REQUEST_URI => $query eq ''
                ? $script
                : "$script?$query",

            SCRIPT_NAME => $url_path,

            SCRIPT_FILENAME => $script,

            QUERY_STRING => $query,

            CONTENT_LENGTH => length($body),

            CONTENT_TYPE => $headers->{'content-type'} // '',

            REMOTE_ADDR => '127.0.0.1',

            REMOTE_HOST => 'localhost',
        );

        # HTTP headers -> CGI environment

        for my $key (keys %$headers) {

            my $name = uc($key);

            $name =~ tr/-/_/;

            next if $key eq 'content-type';

            next if $key eq 'content-length';

            $env{"HTTP_$name"} = $headers->{$key};
        }

        %ENV = %env;

        chdir($ROOT) or die "Cannot change directory: $!";

        exec($^X, $script);

        die "Cannot execute CGI: $!";
    }

    # ----------------------------------------------
    # Parent process
    # ----------------------------------------------

    waitpid($pid, 0);

    my $exit_status = $?;

    # Read CGI output

    open(my $result, '<', $out_file) or die $!;

    binmode($result);

    my $output = do {
        local $/;
        <$result> // '';
    };

    close($result);

    # Read CGI errors

    open(my $errors, '<', $err_file);

    my $error = do {
        local $/;
        <$errors> // '';
    };

    close($errors);

    # Cleanup

    unlink($in_file, $out_file, $err_file);

    # ----------------------------------------------
    # Debug logging
    # ----------------------------------------------

    if ($error ne '') {

        print STDERR "\n";
        print STDERR "========== CGI STDERR ==========\n";
        print STDERR "SCRIPT: $script\n";
        print STDERR $error;
        print STDERR "================================\n\n";
    }

    # ----------------------------------------------
    # CGI execution error
    # ----------------------------------------------

    if ($exit_status != 0) {

        my $message = "CGI execution failed\n\n$error";

        print STDERR "CGI EXIT STATUS: $exit_status\n";

        if ($DEBUG) {

            my $html =
                "<html><body>" .
                "<h1>CGI ERROR</h1>" .
                "<h3>" . html_escape($script) . "</h3>" .
                "<pre>" . html_escape($message) . "</pre>" .
                "</body></html>";

            send_response(
                $client,
                '500 Internal Server Error',
                'text/html; charset=utf-8',
                $html,
                $method
            );

        } else {

            send_response(
                $client,
                '500 Internal Server Error',
                'text/plain',
                'CGI execution failed',
                $method
            );
        }

        return;
    }

    # ----------------------------------------------
    # Parse CGI response
    # ----------------------------------------------

    my ($cgi_headers, $cgi_body) =
        split(/\r?\n\r?\n/, $output, 2);

    unless (defined $cgi_body) {

        $cgi_headers = 'Content-Type: text/plain';

        $cgi_body = $output;
    }

    my $status = '200 OK';

    my @response_headers;

    my $has_type = 0;

    for my $line (split(/\r?\n/, $cgi_headers)) {

        if ($line =~ /^Status:\s*(.+)/i) {

            $status = $1;

            next;
        }

        if ($line =~ /^([A-Za-z0-9-]+):\s*(.*)$/) {

            my ($name, $value) = ($1, $2);

            next if $name =~ /^(Content-Length|Connection|Transfer-Encoding)$/i;

            next if $name =~ /^(Date|Server)$/i;

            if ($name =~ /^Content-Type$/i) {
                $has_type = 1;
            }

            push @response_headers, "$name: $value\r\n";
        }
    }

    if (!$has_type) {

        push @response_headers,
            "Content-Type: text/html; charset=utf-8\r\n";
    }

    if ($status !~ /^\d{3}\s+[\x20-\x7e]+$/) {
        $status = '200 OK';
    }

    my $response =

        "HTTP/1.1 $status\r\n" .

        join('', @response_headers) .

        "Content-Length: " . length($cgi_body) . "\r\n" .

        "Connection: close\r\n" .

        "X-Content-Type-Options: nosniff\r\n" .

        "\r\n";

    print $client $response;

    print $client $cgi_body unless $method eq 'HEAD';
}

# --------------------------------------------------
# Static files
# --------------------------------------------------

sub serve_static {

    my ($client, $file, $method) = @_;

    my %mime = (

        html => 'text/html; charset=ISO-8859-2',

        htm  => 'text/html; charset=ISO-8859-2',

        css  => 'text/css; charset=utf-8',

        js   => 'application/javascript',

        json => 'application/json',

        txt  => 'text/plain; charset=utf-8',

        png  => 'image/png',

        jpg  => 'image/jpeg',

        jpeg => 'image/jpeg',

        gif  => 'image/gif',

        svg  => 'image/svg+xml',

        ico  => 'image/x-icon',

        pdf  => 'application/pdf',
    );

    my ($ext) = $file =~ /\.([^.]+)$/;

    my $type = $mime{lc($ext // '')}
        // 'application/octet-stream';

    open(my $fh, '<', $file) or do {

        send_response(
            $client,
            '500 Internal Server Error',
            'text/plain',
            'Cannot read file'
        );

        return;
    };

    binmode($fh);

    my $data = do {
        local $/;
        <$fh> // '';
    };

    close($fh);

    send_response(
        $client,
        '200 OK',
        $type,
        $data,
        $method
    );
}
