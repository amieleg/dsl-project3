module Wavy::Compile

import Wavy::Syntax;
import Wavy::AST;

import IO;
import util::Math;
import List;
import util::Maybe;
import Map;

int rate = 4410;

list[int] num_to_4_bytes(int n)
{
  int first = n % 256;
  int second = n / 256;
  int third = n / (256*256);
  int fourth = n / (256*256*256);

  return [first, second, third, fourth];
}

list[int] num_to_2_bytes(int n)
{
  int small = n % 256;
  int big = (n-small)/256;
  return [small, big];
}

list[int] get_header(int length)
{
  wav_header = [82, 73, 70, 70] + num_to_4_bytes(36 + (length * 4)) + [87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 2, 0] + num_to_4_bytes(rate) + num_to_4_bytes(rate*4) + [4, 0, 16, 0, 100, 97, 116, 97] + num_to_4_bytes(length * 4);
  return wav_header;
}

int float_to_sample(real f)
{
  int i = round(f * 65535);

  return i;
}

real sawwave(real x)
{
  real tau = 2 * PI();
  int waven = floor(x / tau);
  real phase = x - (waven * tau);

  return ((phase / (2 * PI())) * 2) - 1;
}

real sine(real t, real freq)
{
  return 0.5 * sin(2 * PI() * freq * t / rate);
}

list[int] wave(int length, real freq)
{
  samples = [];

  for(int i <- [0..length])
  {
    sample = float_to_sample(0.5 * sin(2 * PI() * freq * i / rate));
    //sample = float_to_sample(0.5 * sawwave(2 * PI() * freq * i / rate));
    as_2_bytes = num_to_2_bytes(sample);
    samples += as_2_bytes;
    samples += as_2_bytes;
  }

  return samples;
}

void compileF()
 {
  seconds = 1;
  length = seconds * rate;
  wav = get_header(length);

  for(int i <- [0..10])
  {
    wav += wave(floor(0.1 * rate), 800.0 - i * 20);
  }

  testfile = |project://wavy/src/examples/test.wav|;
  writeFileBytes(testfile, wav);
}

map[str, num] VARTABLE = ();
map[str, tuple[list[str] parameters, list[StatementAST] body]] FUNCTABLE = (("Sine": <["t", "freq"], []>));

Maybe[num] eval_func(list[StatementAST] sn, map[str, num] args)
{
  for(StatementAST s <- sn)
  {
    //println(s);
    switch (s)
    {
      case \expression(ExpressionAST expr):
      {
        return just(eval_expression(expr, args));
      }
      case \functionDeclaration(str id, list[str] parameters, list[StatementAST] body):
      {
        FUNCTABLE += (id: <parameters, body>);
      }
      case \output(ExpressionAST result):
      {
        return just(eval_expression(result, args));
      }
      case \if(ExpressionAST condition, list[StatementAST] body):
      {
        if (eval_expression(condition, args) == 1)
        {
          result = eval_func(body, args);
          if (result != nothing())
          {
            return result;
          }
        }
      }
      case \ifelse(ExpressionAST condition, list[StatementAST] true_body, list[StatementAST] false_body):
      {
        if (eval_expression(condition, args) == 1)
        {
          result = eval_func(true_body, args);
          if (result != nothing())
          {
            return result;
          }
        }
        else
        {
          result = eval_func(false_body, args);
          if (result != nothing())
          {
            return result;
          }
        }
      }
      case \while(ExpressionAST condition, list[StatementAST] body):
      {
        while (eval_expression(condition, args) == 1)
        {
          result = eval_func(body, args);
          if (result != nothing())
          {
            return result;
          }
        }
      }
      case \declaration(str id, ExpressionAST expr):
      {
        VARTABLE += (id: eval_expression(expr, args));
      }
    }
  }
  return nothing();
}

map[str, num] instantiate_args(list[str] parameters, list[ExpressionAST] arguments, map[str, num] args)
{
  list[num] evaluated_arguments = [];
  
  for (ExpressionAST e <- arguments)
  {
    evaluated_arguments += eval_expression(e, args);
  }

  map[str, num] outmap = ();
  for (int i <- [0..size(parameters)])
  {
    outmap += (parameters[i]: evaluated_arguments[i]);
  }
  return outmap;
}

num eval_expression(ExpressionAST e, map[str, num] args)
{
  switch (e)
  {
    // math
    case \addition(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) + eval_expression(rhs, args);
    }
    case \subtraction(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) - eval_expression(rhs, args);
    }
    case \multiplication(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) * eval_expression(rhs, args);
    }
    case \division(ExpressionAST lhs, ExpressionAST rhs):
    {
      return eval_expression(lhs, args) / eval_expression(rhs, args);
    }
    case \power(ExpressionAST lhs, ExpressionAST rhs):
    {
        return pow(eval_expression(lhs, args), toReal(eval_expression(rhs, args)));
    }

    // comparison
    case \less(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) < eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \lesseq(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) <= eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \greater(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) > eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \greatereq(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) >= eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    case \equal(ExpressionAST lhs, ExpressionAST rhs):
    {
      if (eval_expression(lhs, args) == eval_expression(rhs, args))
      {
        return 1;
      }
      return -1;
    }
    
    // simple
    case \brackets(ExpressionAST expr):
    {
      return eval_expression(expr,args);
    }
    case \number(num val):
    {
      return val;
    }

    // complex
    case \var(str id):
    {
      if (id in args)
      {
        return args[id];
      }
      return VARTABLE[id];
    }
    case \call(str func, list[ExpressionAST] arguments):
    {
      func_info = FUNCTABLE[func];
      call_args = instantiate_args(func_info[0], arguments, args);
      println(call_args);

      if (func == "Sine")
      {
        println(call_args["freq"]);
        return sine(toReal(call_args["t"]), toReal(call_args["freq"]));
      }

      result = eval_func(func_info[1], call_args);

      switch (result)
      {
        case just(val):
        {
          return val;
        }
      }
    }
  }
  return -1;
}

void compile(WavyAST ast)
{
    list[real] samples = [];
    for (i <- [0..rate])
    {
        result = eval_func(ast.program,("t": i));

        switch(result)
        {
            case just(n):
            {
                samples += n;
                
            }
        }
    }
    
    wav = get_header(rate);

    for(f <- samples)
    {
        as_2_bytes = num_to_2_bytes(float_to_sample(f));
        wav += as_2_bytes;
        wav += as_2_bytes;
    }

    testfile = |project://wavy/texts/test.wav|;
    writeFileBytes(testfile, wav);
}