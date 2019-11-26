local sub_filter_regexs = require('sub_filter_regexs') 
local rex = require('rex_posix')

describe("sub_filter_regexs", function()
    describe("head_tag_regex", function()
        it("matches_head_tag", function()
            local head_tag = "<head>"

            local found_head_tag = rex.match(head_tag, sub_filter_regexs.head_tag_regex)

            assert.is_true(head_tag == found_head_tag)
        end)

        it("matches head tag with attributes", function()
            local head_tag = "<head class=\"loc head\">"

            local found_head_tag = rex.match(head_tag, sub_filter_regexs.head_tag_regex)

            assert.is_true(head_tag == found_head_tag)
        end)

        it("does not match header tag", function()
            local head_tag = "<header>"

            local found_head_tag = rex.match(head_tag, sub_filter_regexs.head_tag_regex)

            assert.is_nil(found_head_tag)
        end)
    end)
end)
