const std = @import("std");
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const parser = @import("parser.zig");
const TokenStream = parser.TokenStream;


pub const Node = struct {
    id: u32 = 0,
    generation: u32 = 0,
};

pub const NodeString = ArrayList(u8);
pub const NodeStringView = []const u8;

pub const NodeType = enum(u8) {
    Dead, // set to this to effectively mark this node as dead
    Text,
    Response,
};

const StoryNodes = struct {
    instances: ArrayList(Node),
    textContent: ArrayList(NodeString),
    speakerName: AutoHashMap(Node, NodeString),
    choices: AutoHashMap(u32, ArrayList(u32)),
    nextNode: AutoHashMap(u32, u32),

    labels: AutoHashMap(NodeString, u32),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .instances = ArrayList(Node).init(allocator),
            .textContent = ArrayList(NodeString).init(allocator),
            .speakerName = AutoHashMap(Node, NodeString).init(allocator),
            .choices = AutoHashMap(u32, ArrayList(u32)).init(allocator),
            .nextNode = AutoHashMap(u32, u32).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.instances.deinit();

        {
            for (self.textContent.items) |instance| {
                instance.deinit();
            }
            self.textContent.deinit();
        }

        {
            var iter = self.speakerName.iterator();
            while (iter.next()) |instance| {
                instance.value_ptr.deinit();
            }
            self.speakerName.deinit();
        }

        {
            var iter = self.choices.iterator();
            while (iter.next()) |instance| {
                instance.value_ptr.deinit();
            }
            self.choices.deinit();
        }

        self.nextNode.deinit();
    }
};

test "init and deinit" 
{
    var x = StoryNodes.init(std.testing.allocator);
    defer x.deinit();
}

test "Parse simple" {
    const TokenType = parser.TokenStream.TokenType;
    _ = TokenType;

    var tokStream = try TokenStream.MakeTokens(parser.easySampleData, std.testing.allocator);
    defer tokStream.deinit();

    tokStream.test_display();
    const ParseState = enum{
        default,
        attributeDefinition,
        funcArgsParse,
    };

    var parseState:ParseState = default;
    var isParsing = true;
    var story = StoryNodes.init(std.testing.allocator);
    defer story.deinit();

    var currentAttributes = ArrayList(NodeString).init(std.testing.allocator);

    var i = 0;
    while(isParsing)
    {
        const tokType = tokStream.token_types[i];
        const tokData = tokStream.tokens[i];
        var shouldBreak = false;
        switch(parseState) {
            .default => {
                if(!shouldBreak and tokType == TokenType.L_SQBRACK)
                {
                    shouldBreak = true;
                    parseState = .attributeDefinition;
                }
                if(!shouldBreak and tokType == TokenType.AT)
                {
                    if(i + 1 >= tokStream.token_types.len) unreachable;
                    if(tokStream.token_types[i + 1] != TokenType.LABEL) unreachable; // error, expected label after @ 
                    if(std.mem.eql(u8, tokStream.tokens[i + 1], "goto"))
                    {
                        // todo this creates a link
                        i += 1;
                    }
                    //else if (std.mem.eql(u8, tokStream.tokens[i + 1], "if")){
                    //}
                    else
                    {
                        if(i + 2 >= tokStream.token_types.len) unreachable; // we expected arguments but reached end of file
                        {
                            if(tokStream.token_types[i + 2] == TokenType.L_PAREN)
                            {
                                shouldBreak = true;
                                parseState = .funcArgsParse;
                                i += 1; // consume the L_Paren
                            }
                        }
                    }
                    i += 1;
                }
            },
            .attributeDefinition => {
                isParsing = false;

                if(!shouldBreak and tokType == TokenType.R_SQBRACK)
                {
                    shouldBreak = true;
                    parseState = .default;
                }
            },
            .funcArgsParse => {
                if(!shouldBreak and tokType == TokenType.R_PAREN)
                {
                    shouldBreak = true;
                    parseState = .default;
                }
            }
        }
        i += 1;
    }

    _ = story;
    _ = i;
}