#! /usr/bin/env perl
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request;
use JSON;

# Setting
my $slackHookUrl;
my $COIN;
my $TO;
my $FIAT;
my $tickerAlertPercentage;
my $tradeMinAmount;
my $tradeMinPercentage;

# Data
my $filename = "data.json";
my $dataJson = undef;

my $fnret = main();
writeData();
if ( not $fnret )
{
    print $fnret;
    exit 1;
}
    
print $fnret;
exit 0;

sub main
{
    my $fnret = readConfig();
    not $fnret and return $fnret;

    my $fnret = readData();
    not $fnret and return $fnret;

    # Ticker
    $fnret = tickerAlert();
    not $fnret and return $fnret;

    # Trades
    $fnret = livecoinTrade();
    not $fnret and return $fnret;

    $fnret = altmarketsTrade();
    not $fnret and return $fnret;

    return Result->Ok();
}

sub readConfig
{
    if (open(my $fh, '<:encoding(UTF-8)', 'config.json'))
    {
        my $configText = join('', <$fh>);
        my $json = JSON->new;
        my $configJson = $json->decode($configText);

        $slackHookUrl = $configJson->{'slack_hook'};
        $COIN = $configJson->{'coin'};
        $TO = $configJson->{'to'};
        $FIAT = $configJson->{'fiat'};
        $tickerAlertPercentage = $configJson->{'ticker_alert_percentage'};
        $tradeMinAmount = $configJson->{'trade_min_amount'};
        $tradeMinPercentage = $configJson->{'trade_min_percentage'};

        close($fh);
    }
    else
    {
        return Result->INTERNAL_ERROR('Impossible to read config.json');
    }

    return Result->Ok();    
}

sub tickerAlert
{
    print "[DEBUG] Calling Ticker API \n";
    # Get Ticker
    my $browser = LWP::UserAgent->new;
    my $resp = $browser->get('https://api.livecoin.net/exchange/ticker?currencyPair=' . $COIN . '/' . $TO);

    if( not $resp->is_success() )
    {
        return Result->INTERNAL_ERROR($resp->status_line);
    }

    my $json = JSON->new;
    $data = $json->decode($resp->decoded_content);

    my $satPrice =  $data->{'last'} * 100000000;

    # Check price change
    if( $dataJson->{'lastPrice'} == 0 )
    {
        slackNotification($COIN . ' Alert - Price is now at '. $satPrice . ' Satoshi');     
    }
    else
    {
        my $diffPercentage = (($satPrice - $dataJson->{'lastPrice'}) / $dataJson->{'lastPrice'}) * 100;
        if( abs($diffPercentage) >= $tickerAlertPercentage )
        {
            if( $diffPercentage > 0 )
                {
                slackNotification($COIN . ' Alert - Price is now at '. $satPrice . ' Satoshi. That\'s a change of ~ +' . int($diffPercentage) . '%');
            }
            else
            {
                slackNotification($COIN . ' Alert - Price is now at '. $satPrice . ' Satoshi. That\'s a change of ~ -' . abs(int($diffPercentage)) . '%');
            }
        }
    }
    $dataJson->{'lastPrice'} = $satPrice;

    return Result->Ok();
}

sub livecoinTrade
{
    print "[DEBUG] Calling Livecoin API \n";
    # Get Order Book
    my $browser = LWP::UserAgent->new;
    my $resp = $browser->get('https://api.livecoin.net/exchange/order_book?currencyPair=' . $COIN . '/' . $TO);

    if( not $resp->is_success() )
    {
        return Result->INTERNAL_ERROR($resp->status_line);
    }

    my $json = JSON->new;
    $data = $json->decode($resp->decoded_content);

    my @foundAsks = ();

    foreach my $ask ( @{$data->{'asks'}} )
    {
        my ($price, $quantity, $timestamp) = @{$ask};
        if( $quantity < $tradeMinAmount )
        {
            next;
        }

        my $satPrice = $price * 100000000;
        my $diffPercentage = (($satPrice - $dataJson->{'lastPrice'}) / $dataJson->{'lastPrice'}) * 100;
        if( abs($diffPercentage) > $tradeMinPercentage )
        {
            next;
        }
        

        # checking if exist
        my $found = 0;
        foreach my $checkAsk ( @{$dataJson->{'livecoin-asks'}} )
        {
            my @checkAskArr = @{$checkAsk};
            if( $checkAskArr[0] ne $satPrice or $checkAskArr[1] ne $quantity or $checkAskArr[2] ne $timestamp ) 
            {
                next;
            }
            $found = 1;
            last;
        }
        if( $found == 0 )
        {
            slackNotification($COIN . ' Alert - Someone submitted a sell order for ' . $quantity . ' ' . $COIN . ' at '. $satPrice . ' Satoshi on Livecoin');       
        }

        push(@foundAsks, [$satPrice, $quantity, $timestamp]);
    }

    my @foundBids = ();

    foreach my $bid ( @{$data->{'bids'}} )
    {
        my ($price, $quantity, $timestamp) = @{$bid};
        if( $quantity < $tradeMinAmount )
        {
            next;
        }
        
        my $satPrice = $price * 100000000;
        my $diffPercentage = (($satPrice - $dataJson->{'lastPrice'}) / $dataJson->{'lastPrice'}) * 100;
        if( abs($diffPercentage) > $tradeMinPercentage )
        {
            next;
        }
        

        # checking if exist
        my $found = 0;
        foreach my $checkAsk ( @{$dataJson->{'livecoin-bids'}} )
        {
            my @checkAskArr = @{$checkAsk};
            if( $checkAskArr[0] ne $satPrice or $checkAskArr[1] ne $quantity or $checkAskArr[2] ne $timestamp ) 
            {
                next;
            }
            $found = 1;
            last;
        }
        if( $found == 0 )
        {
            slackNotification($COIN . ' Alert - Someone submitted a buy order for ' . $quantity . ' ' . $COIN . ' at '. $satPrice . ' Satoshi on Livecoin');        
        }

        push(@foundBids, [$satPrice, $quantity, $timestamp]);
    }

    $dataJson->{'livecoin-asks'} = \@foundAsks;
    $dataJson->{'livecoin-bids'} = \@foundBids;

    return Result->Ok();
}

sub altmarketsTrade
{
    print "[DEBUG] Calling altmarkets API \n";
    # Get Order Book
    my $browser = LWP::UserAgent->new;
    $browser->agent("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/83.0.4103.61 Chrome/83.0.4103.61 Safari/537.36");
    my $resp = $browser->get('https://altmarkets.io/api/v2/order_book?market=' . lc($COIN) . lc($TO) . '&asks_limit=200&bids_limit=200');

    if( not $resp->is_success() )
    {
        return Result->INTERNAL_ERROR($resp->status_line);
    }

    my $json = JSON->new;
    $data = $json->decode($resp->decoded_content);

    my @foundAsks = ();

    foreach my $ask ( @{$data->{'asks'}} )
    {
        my $price    = $ask->{'price'};
        my $quantity = $ask->{'volume'};
        my $timestamp = $ask->{'created_at'}; 

        if( $quantity < $tradeMinAmount )
        {
            next;
        }
        
        my $satPrice = $price * 100000000;
        my $diffPercentage = (($satPrice - $dataJson->{'lastPrice'}) / $dataJson->{'lastPrice'}) * 100;
        if( abs($diffPercentage) > $tradeMinPercentage )
        {
            next;
        }
        

        # checking if exist
        my $found = 0;
        foreach my $checkAsk ( @{$dataJson->{'altmarkets-asks'}} )
        {
            my @checkAskArr = @{$checkAsk};
            if( $checkAskArr[0] ne $satPrice or $checkAskArr[1] ne $quantity or $checkAskArr[2] ne $timestamp ) 
            {
                next;
            }
            $found = 1;
            last;
        }
        if( $found == 0 )
        {
            slackNotification($COIN . ' Alert - Someone submitted a sell order for ' . $quantity . ' ' . $COIN . ' at '. $satPrice . ' Satoshi on AltMarkets');     
        }

        push(@foundAsks, [$satPrice, $quantity, $timestamp]);
    }

    my @foundBids = ();

    foreach my $bid ( @{$data->{'bids'}} )
    {
        my $price    = $ask->{'rate'};
        my $quantity = $ask->{'quantity'};
        my $timestamp = $ask->{'created_at'}; 

        if( $quantity < $tradeMinAmount )
        {
            next;
        }
        
        my $satPrice = $price * 100000000;
        my $diffPercentage = (($satPrice - $dataJson->{'lastPrice'}) / $dataJson->{'lastPrice'}) * 100;
        if( abs($diffPercentage) > $tradeMinPercentage )
        {
            next;
        }
        

        # checking if exist
        my $found = 0;
        foreach my $checkAsk ( @{$dataJson->{'altmarkets-bids'}} )
        {
            my @checkAskArr = @{$checkAsk};
            if( $checkAskArr[0] ne $satPrice or $checkAskArr[1] ne $quantity or $checkAskArr[2] ne $timestamp ) 
            {
                next;
            }
            $found = 1;
            last;
        }
        if( $found == 0 )
        {
            slackNotification($COIN . ' Alert - Someone submitted a buy order for ' . $quantity . ' ' . $COIN . ' at '. $satPrice . ' Satoshi on AltMarkets');      
        }

        push(@foundBids, [$satPrice, $quantity, $timestamp]);
    }

    $dataJson->{'altmarkets-asks'} = \@foundAsks;
    $dataJson->{'altmarkets-bids'} = \@foundBids;

    return Result->Ok();
}

sub slackNotification
{
    my $msg = shift;

    print "[DEBUG] $msg \n";

    my $body = {
        'text' => $msg,
    };

    my $req = HTTP::Request->new( 'POST', $slackHookUrl );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content( encode_json($body) );
    my $lwp = LWP::UserAgent->new;
    my $resp = $lwp->request( $req );

    if( not $resp->is_success() )
    {
        return Result->INTERNAL_ERROR($resp->status_line);
    }

    return Result->Ok();
}

sub readData
{
    if (open(my $fh, '<:encoding(UTF-8)', $filename))
    {
        my $dataText = <$fh>;
        my $json = JSON->new;
        $dataJson = $json->decode($dataText);

        close($fh);
    }
    else
    {
        $dataJson = {
            'lastPrice'            => 0,
            'livecoin-bids'        => [],
            'livecoin-asks'        => [],
            'altmarkets-bids'      => [],
            'altmarkets-asks'      => [],
        };
    }

    return Result->Ok();    
}

sub writeData
{
    if( not defined $dataJson )
    {
        return Result->INTERNAL_ERROR();
    }
 
    my $json = JSON->new;
    my $dataText = $json->encode($dataJson);

    open(my $fh, '>', $filename) or
        return Result->INTERNAL_ERROR();

    print $fh $dataText;

    close($fh);
    
    return Result->Ok();
}

# -------------------------------------
# Package for Result
# -------------------------------------
{
    package Result;
    use overload ( 
        'bool'     => \&validResult,
        '""'       => \&stringify,
        'fallback' => 1,
    );
    use Data::Dumper;

    BEGIN {
        our @status = (
            {
                'code'    => 100,
                'names'   => [qw/ok Ok OK oK/],
            },
            {
                'code'    => 500,
                'names'   => [qw/INTERNAL_ERROR/],
            }
        );

        foreach my $result ( @status )
        {
            my @names = @{$result->{'names'}};
            my $mainName = shift(@names);
            my $code = $result->{'code'};

            eval "
                sub $mainName
                {
                    my \$this = shift;
                    my \$value = shift;
                    
                    return bless({
                            'status' => $code,
                            " . (($code >= 100 and $code < 200 ) ? "'value'  => \$value," : "'msg'  => \$value,") .
"                        }, $this );
                }
            ";

            foreach my $name ( @names )
            {
                eval "
                    *$name = \\&$mainName;
                ";
            }
        }

    }

    sub validResult
    {
        my $this = shift;

        if( $this->{'status'} >= 100 and $this->{'status'} < 200 )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }

    sub stringify
    {
        my $this = shift;

        if( $this->validResult() )
        {
            return 'Action is a success('.$this->{'status'}.').' . (($this->{'msg'}) ? 'Message : ' . $this->{'msg'} : '') . "\n";
        }
        else
        {
            return 'Action has failed('.$this->{'status'}.').' . (($this->{'msg'}) ? 'Error Message : ' . $this->{'msg'} : '') . "\n";
        }
        return 0;
    }
}

