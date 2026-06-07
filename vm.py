class VM(object):
    def __init__(self):
        self.r1 = 0
        self.r2 = 0
        self.N = 0
        self.trace = []

    def exec(self, instructions: [str]):
        instructions.append('nop')
        
        for inst in instructions:
            args = inst.split(' ')
            self.eval(args)

        self.N = 1 << len(self.trace).bit_length()

        for i in range(len(self.trace), self.N):
            self.eval(['nop'])

        return self.trace

    def eval(self, args: [str]):
        op = args[0]
        args = args[1:]

        if op == 'set':
            if len(args) < 1:
                raise  Exception(f'op set should has one arg')
    
            self.trace.append([self.r1, self.r2, int(args[0]), 1, 0, 0, 0, 0])
            self.r2 = int(args[0])
        elif op == 'swap':
            self.trace.append([self.r1, self.r2, 0, 0, 1, 0, 0, 0])
            self.r1, self.r2 = self.r2, self.r1
        elif op == 'add':
            self.trace.append([self.r1, self.r2, 0, 0, 0, 1, 0, 0])
            self.r1 = self.r1 + self.r2
        elif op == 'mul':
            self.trace.append([self.r1, self.r2, 0, 0, 0, 0, 1, 0])
            self.r1 = self.r1 * self.r2
        elif op == 'nop':
            self.trace.append([self.r1, self.r2, 0, 0, 0, 0, 0, 1])
        else:
            raise Exception(f'Unknown opcode: {op}')
