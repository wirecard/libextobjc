//
//  EXTScopeTest.m
//  extobjc
//
//  Created by Justin Spahr-Summers on 2011-05-04.
//  Released into the public domain.
//

#import "EXTScopeTest.h"

@interface EXTScopeTest ()
- (void)nestedAppend:(NSMutableString *)str;
@end

@implementation EXTScopeTest

- (void)testOnExit {
	NSMutableString *str = [@"foo" mutableCopy];
	@onExit {
		[str release];
	};

	{
		@onExit {
			[str appendString:@"bar"];
		};
	}

	STAssertEqualObjects(str, @"foobar", @"'bar' should've been appended to 'foo' at the end of the previous scope");

	__block unsigned executed = 0;

	for (unsigned i = 1;i <= 3;++i) {
		@onExit {
			executed += i;
		};
	}

	STAssertEquals(executed, 6U, @"onExit blocks should be executed on loop iterations");

	executed = 0;
	for (unsigned i = 1;i <= 4;++i) {
		@onExit {
			executed += i;
		};

		if (i > 3)
			break;

		if (i % 2 == 0)
			continue;
	}

	STAssertEquals(executed, 10U, @"onExit blocks should be executed even when break or continue is used");

	executed = 0;
	{
		{
			@onExit {
				++executed;
			};

			goto skipStuff;
			executed = 10;
		}
		
		skipStuff:
			++executed;
	}

	STAssertEquals(executed, 2U, @"onExit blocks should be executed even when goto is used");

	str = [@"foo" mutableCopy];
	@onExit {
		[str release];
	};

	[self nestedAppend:str];

	STAssertEqualObjects(str, @"foobar", @"'bar' should've been appended to 'foo' at the end of a called method that exited early");
}

- (void)nestedAppend:(NSMutableString *)str {
	@onExit {
		[str appendString:@"bar"];
	};

	if ([str isEqualToString:@"foo"])
		return;
	
	[str appendString:@"buzz"];
}

- (void)testLexicalOrdering {
	__block unsigned lastBlockEntered = 0;

	{
		@onExit {
			STAssertEquals(lastBlockEntered, 2U, @"lexical ordering of @onExit blocks is not correct!");

			lastBlockEntered = 1;
		};

		@onExit {
			STAssertEquals(lastBlockEntered, 3U, @"lexical ordering of @onExit blocks is not correct!");

			lastBlockEntered = 2;
		};

		@onExit {
			STAssertEquals(lastBlockEntered, 4U, @"lexical ordering of @onExit blocks is not correct!");

			lastBlockEntered = 3;
		};

		@onExit {
			STAssertEquals(lastBlockEntered, 0U, @"lexical ordering of @onExit blocks is not correct!");

			lastBlockEntered = 4;
		};
	}

	STAssertEquals(lastBlockEntered, 1U, @"lexical ordering of @onExit blocks is not correct, or cleanup blocks did not execute at all!");
}

@end