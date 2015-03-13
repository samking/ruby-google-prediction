# Features #

  * Generates an auth token from a google account
  * Trains using the auth token and data uploaded to Google Storage for Developers
  * Checks the training status
  * Predicts outputs when given new input

# Install #

sudo gem install google-prediction

# Usage #
Also, see the RDoc

```
auth_token = GooglePrediction.get_auth_token('foo@gmail.com', 'password')
  => long string of letters and numbers
predictor = GooglePrediction.new(auth_token, 'bucket', 'object')
predictor.train
  => {"data"=>{"data"=>"bucket/object"}}
predictor.check_training
  => "Training has not completed"

wait_some_time

predictor.check_training
  => "no estimate available" or something between "0.0" and "1.0"
predictor.predict "awesome company"
  => "Google"
predictor.predict "awesome nonprofit"
  => "InSTEDD"
predictor.predict 13
  => "lucky"
predictor.predict [3, 5, 7, 11]
  => "prime"
```

# Contact #
support@instedd.org
samking@cs.stanford.edu