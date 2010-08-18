# Provides an interface to the Google Prediction API.
#
# Author::    Sam King (samking@cs.stanford.edu)
# Copyright:: InSTEDD[http://instedd.org]
# License::   GPLv3

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'
require 'curb'
require 'json'

module GooglePrediction
  VERSION = '0.1.0'

  # = Usage
  #
  # auth_token = GooglePrediction.client_login('foo@gmail.com', 'password')
  #   => long string of letters and numbers
  #
  # predictor = GooglePrediction.new(auth_token, 'bucket', 'object')
  #
  # predictor.#invoke_training
  #   => {"data"=>{"data"=>"bucket/object"}}
  #
  # predictor.#get_training_status
  #   => "Training has not completed"
  # 
  # wait_some_time
  # 
  # predictor.#get_training_status
  #   => "no estimate available" or something between "0.0" and "1.0"
  # 
  # predictor.#get_prediction "awesome company"
  #   => "Google"
  # predictor.#get_prediction "awesome nonprofit"
  #   => "InSTEDD"
  # predictor.#get_prediction 13
  #   => "lucky"
  # predictor.#get_prediction [3, 5, 7, 11]
  #   => "prime"
  class GooglePrediction
    PREDICTION_URL_PREFIX = 'https://www.googleapis.com/prediction/v1/training'

    attr_reader :auth_code
    attr_reader :bucket
    attr_reader :object

    # Gets the auth code from Google's ClientLogin using the provided email 
    # and password.  
    #
    # This will fail if Google requires a Captcha.  If so, follow the 
    # instructions at  
    # http://code.google.com/apis/predict/docs/getting-started.html
    # and pass in the new URL and new arguments using the optional parameters.
    def self.client_login(email, password, url='https://www.google.com/accounts/ClientLogin', args={}) 
      curl = Curl::Easy.new(url)
      post_args = {
        "accountType" => "HOSTED_OR_GOOGLE",
        "Email" => email,
        "Passwd" => curl.escape(password),
        "source" => "companyName-applicationName-versionID",
        "service" => "xapi"
      }
      args.each {|key, val| post_args[key] = val }
      post_fields = post_args.map {|k,v| Curl::PostField.content(k, v) }
      curl.http_post(post_fields)
      curl.body_str.match('Auth.*')[0][5..-1]
    end

    # auth_code: the login code generated from self.client_login
    #
    # bucket: the name of the bucket in Google Storage
    #
    # object: the filename of the object to do prediction on
    def initialize(auth_code, bucket, object)
      @auth_code=auth_code
      @bucket=bucket
      @object=object
    end

    # Wrapper.  Creates a new object and runs invoke_training on it.
    def self.invoke_training(auth_code, bucket, object)
      predictor = GooglePrediction.new(auth_code, bucket, object)
      predictor.invoke_training
    end

    # Wrapper.  Creates a new object and runs get_training_status on it.
    def self.get_training_status(auth_code, bucket, object)
      predictor = GooglePrediction.new(auth_code, bucket, object)
      predictor.get_training_status
    end

    # Wrapper.  Creates a new object and runs get_prediction on it.
    def self.get_prediction(auth_code, bucket, object, submission)
      predictor = GooglePrediction.new(auth_code, bucket, object)
      predictor.get_prediction(submission)
    end

    # Starts training on the specified object.  
    # 
    # Returns 
    #   {"data"=>{"data"=>"bucket/object"}}
    # on success, and 
    #   {"errors"=>{"errors"=>[{all of your errors}], "code"=>code, "message"=>message}}
    # on error.
    def invoke_training
      url = PREDICTION_URL_PREFIX + "?data=" + @bucket + "%2F" + @object
      curl = Curl::Easy.new(url)
      curl.post_body = JSON.generate({:data => {}})
      curl.headers = {"Content-Type" => "application/json", 
        "Authorization" => "GoogleLogin auth=#{@auth_code}"}
      curl.http("POST")
      JSON.parse(curl.body_str)
    end

    # Gets the training status of the specified object.
    # 
    # If the training is incomplete, returns "Training has not completed".  
    # If the training did not have enough data to do cross-fold validation, 
    # returns "no estimate available".
    # If the training went as desired, returns the accuracy of the training 
    # from 0 to 1.
    #   
    # Returns
    #   {"errors"=>{"errors"=>[{all of your errors}], "code"=>code, "message"=>message}}
    # on error.
    def get_training_status
      url = PREDICTION_URL_PREFIX + "/" + @bucket + "%2F" + @object
      curl = Curl::Easy.new(url)
      curl.headers = {"Authorization" => "GoogleLogin auth=#{@auth_code}"}
      curl.http_get

      # response will be 
      #   {"data"=>{"data"=>"bucket/object", "modelinfo"=>accuracy_prediction}}
      # on success
      response = JSON.parse(curl.body_str) 
      return response["data"]["modelinfo"] unless response["data"].nil?
      return response
    end

    # Submission must be either a string, a single number, 
    # or an array of numbers
    # 
    # Gets the prediction for the label of the submission based on the training.
    # 
    # Returns the prediction on success and
    #   {"errors"=>{"errors"=>[{all of your errors}], "code"=>code, "message"=>message}}
    # on error. 
    def get_prediction(submission)
      url = PREDICTION_URL_PREFIX + "/" + @bucket + "%2F" + @object + "/predict"
      curl = Curl::Easy.new(url)
      post_body = {:data => {:input => {}}}
      if submission.is_a? String
        post_body[:data][:input] = {:text => [submission]}
      elsif submission.is_a? Fixnum
        post_body[:data][:input] = {:numeric => [submission]}
      elsif submission.is_a? Array
        post_body[:data][:input] = {:numeric => submission}
      else
        raise Exception.new("submission must be String, Fixnum, or Array")
      end
      curl.post_body = JSON.generate(post_body)
      curl.headers = {"Content-Type" => "application/json", 
        "Authorization" => "GoogleLogin auth=#{@auth_code}"}
      curl.http("POST")

      # response will be
      #   {"data"=>{"output"=>{"output_label"=>label}}}
      # on success
      response = JSON.parse(curl.body_str)
      return response["data"]["output"]["output_label"] unless response["data"].nil?
      return response
    end

  end

end