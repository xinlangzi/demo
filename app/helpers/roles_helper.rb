module RolesHelper

  def render_role_tree(tree)
      ret = ''
      ret += "<ul class='tree'>"

      tree.each_key do |r|
          ret += '<li>' + r  # list roles
          h= tree[r] # get hash of controllers/[actions]
          unless h.empty?
              ret += '<ul>'
              h.each_key do |c|
                  ret += '<li>' + c # list controllers
                  a= h[c]
                  unless a.empty?
                      ret += '<ul>'
                      a.each do |an|
                          ret += '<li>' + an + '</li>' # list actions
                      end
                      ret += '</ul>'
                  end
                  ret += '</li>'
              end
              ret += '</ul>'
          end
          ret += '</li>'
      end
      ret += '</ul>'
      ret
  end

  def render_rights_tree(tree)
      ret = ''
      ret += "<ul class='tree'>"

      tree.each_key do |r|
          ret += "<li><a href=\"#\">#{r}</a>"# list controllers
          aa= tree[r] # get array of actions
          unless aa.empty?
              ret += '<ul>'
              ret += "<li><a href=\"#\" onclick=\"App.checkAll('right[#{r}][]'); return false;\">Check All</a>"
              aa.each do |a|
                  ret += '<li>' + "<input type=\"checkbox\" name=\"right[#{r}][]\" value=\"#{a}\" />" + a + '</li>' # list actions
              end
              ret += '</ul>'
          end
          ret += '</li>'
      end
      ret += '</ul>'
      ret
  end

end
