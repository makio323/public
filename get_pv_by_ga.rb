# Set env variables of the Google Auth Library for Ruby - https://github.com/googleapis/google-auth-library-ruby#example-environment-variables
# Reference from CoryFoy/analytics.rb - https://gist.github.com/CoryFoy/9edf1e039e174c00c209e930a1720ce0

# export GOOGLE_ACCOUNT_TYPE="service_account"
# export GOOGLE_CLIENT_ID="xxxxx"
# export GOOGLE_CLIENT_EMAIL="xxxxx"
# export GOOGLE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----xxxx\n-----END PRIVATE KEY-----\n


require 'google/apis/analyticsreporting_v4'
require 'googleauth'

include Google::Apis::AnalyticsreportingV4
include Google::Auth


@client = AnalyticsReportingService.new
@creds = ServiceAccountCredentials.make_creds({:scope => 'https://www.googleapis.com/auth/analytics.readonly'})                                             
                                                   
@client.authorization = @creds
@client.quota_user= user.id

grr = GetReportsRequest.new
rr = ReportRequest.new

rr.view_id = ENV['GOOGLE_ANALYTICS_VIEW_ID'] 
if Rails.env.production? || Rails.env.stagetest?
  rr.filters_expression="ga:pageTitle==#{self.name} | 123ish #{I18n.options_for_title[I18n.locale]}"
else
  # need to update this later - once it's deployed on stagetest site
  rr.filters_expression="ga:pageTitle==Review Pelembab Wajah Fair and Lovely | 123ish Indonesia"
end

#We want the number of sessions
metric1 = Metric.new
metric1.expression = "ga:uniquePageviews"

metric2 = Metric.new
metric2.expression = "ga:avgTimeOnPage"

rr.metrics = [metric1, metric2]

# For this week pageviews
this_week_range = DateRange.new
this_week_range.start_date = "7daysAgo"
this_week_range.end_date = "today"

# for total pageviews
total_range = DateRange.new
total_range.start_date = self.created_at.strftime('%Y-%m-%d') # start date is the date of created entry
total_range.end_date = "today"

rr.date_ranges = [this_week_range, total_range]

grr.report_requests = [rr]

begin
  response = @client.batch_get_reports(grr)

  #puts response.inspect
  #puts "     "
  #puts response.reports.inspect

  this_week_pv_by_ga = response.reports[0].data.totals[0].values[0].to_i rescue 'Error'
  total_pv_by_ga = response.reports[0].data.totals[1].values[0].to_i rescue 'Error'
  this_week_avgTime = Time.at(response.reports[0].data.totals[0].values[1].to_f).utc.strftime("%M:%S") rescue 'Error'
  total_avgTime = Time.at(response.reports[0].data.totals[1].values[1].to_f).utc.strftime("%M:%S") rescue 'Error'
  {'this_week'=>this_week_pv_by_ga, 'total'=>total_pv_by_ga, 'this_week_avgTime'=>this_week_avgTime, 'total_avgTime'=>total_avgTime}
rescue Exception => e
  puts '*** Begin: Error from Google Analytics API ***'
  puts e.to_s
  puts '*** End: Error from Google Analytics API ***'
  # Just return hard coded for now
  {'this_week'=>100, 'total'=>1000, 'this_week_avgTime'=>100, 'total_avgTime'=>1000}
end
