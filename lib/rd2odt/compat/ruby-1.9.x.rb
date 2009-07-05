# rubyzip-0.9.1 is not supported on Ruby 1.9.x.
# Because Ruby 1.9.x is NOT contain ftools.rb.
# 
# This problem is resolved:
#   http://sourceforge.net/tracker/?func=detail&aid=2731184&group_id=43107&atid=435172
# But rubyzip is not released yet.
# 
# So, rd2odt is contain ftools.rb (Ruby 1.8.7p174)
# for running with rubyzip-0.9.1 on Ruby 1.9.x.

$:.push(File.join(File.dirname(__FILE__), "ruby-1.9.x"))
