{-# LANGUAGE GADTs #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Util.Util where -- this module name is a sin against god, todo something descriptive


import           Control.Monad.Except
import           Data.List (intercalate)

import qualified Data.Comp.Multi.Algebra as C
import qualified Data.Comp.Multi.HFunctor as C
import           Data.Comp.Multi.HFunctor ((:->))
import qualified Data.Comp.Multi.Term as C
import           Data.Comp.Multi.Ops ((:&:)(..), (:+:)(..))

import           Util.MyCompose
import           Data.Functor.Const

import qualified Data.Comp.Multi.Ops as C

mapErrUtil :: Functor m => (e -> e') -> ExceptT e m a -> ExceptT e' m a
mapErrUtil f = mapExceptT (fmap (either (Left . f) Right))

type Name = String
type FileChunk = String

data DirTree a i where
  -- file chunk bits
  Leaf :: FileChunk -> DirTree a FileChunk
  BlobNode :: [a FileChunk] -> DirTree a FileChunk

  -- dir and file bits
  FileNode :: Name -> a FileChunk -> DirTree a ()
  DirNode :: Name -> [a ()] -> DirTree a ()

instance C.HFunctor DirTree where
  hfmap _ (Leaf fc)        = Leaf fc
  hfmap f (BlobNode fcs)   = BlobNode $ fmap f fcs
  hfmap f (FileNode n fnc) = FileNode n $ f fnc
  hfmap f (DirNode n dncs)  = DirNode n $ fmap f dncs

type MyDirTree  = C.Term DirTree ()
type MyBlobTree = C.Term DirTree FileChunk

leaf :: FileChunk -> MyBlobTree
leaf =
  C.Term . Leaf

blobTree :: MyBlobTree
blobTree = C.Term (BlobNode [leaf "foo", leaf "bar", leaf "baz"])

dir :: [MyDirTree] -> MyDirTree
dir xs = C.Term (DirNode "mydir" xs)

file :: MyBlobTree -> MyDirTree
file x = C.Term (FileNode "myfile" x)

testDir :: MyDirTree
testDir = dir [file blobTree, dir [file blobTree]]

printCata :: forall i. C.Term DirTree i -> String
printCata = getConst . C.cata alg
  where
    -- NOTE: feels like x should be i?
    alg :: forall x. DirTree (Const String) x -> Const String x
    alg (Leaf x)       = Const $ "leaf:" ++ x
    alg (BlobNode xs)  = Const $ "blobNode: [" ++ intercalate ", " (fmap getConst xs) ++ "]"
    alg (FileNode n x) = Const $ "file(" ++ n ++ "): " ++ getConst x
    alg (DirNode n xs) = Const $ "dir(" ++ n ++ "): [" ++ intercalate ", " (fmap getConst xs) ++ "]"



printCata' :: forall i. C.Term (DirTree :&: String) i -> String
printCata' = getConst . C.cata alg
  where
    alg :: forall x. (DirTree :&: String) (Const String) x -> Const String x
    alg (Leaf x       :&: s)
      = Const $ "leaf[#" ++ s ++ "]:" ++ x
    alg (BlobNode xs  :&: s)
      = Const $ "blobNode[#" ++ s ++ "]: [" ++ intercalate ", " (fmap getConst xs) ++ "]"
    alg (FileNode n x :&: s)
      = Const $ "file[#" ++ s ++ "](" ++ n ++ "): " ++ getConst x
    alg (DirNode n xs :&: s)
      = Const $ "dir[#" ++ s ++ "](" ++ n ++ "): [" ++ intercalate ", " (fmap getConst xs) ++ "]"


-- printCata''
--   :: forall i
--    . C.Term (Compose ((,) String) :++ DirTree) i
--   -> String
-- printCata'' = getConst . C.cata alg
--   where
--     alg :: forall x. (Compose ((,) String) :++ DirTree) (Const String) x -> Const String x
--     alg (HC (Compose (s, Leaf x)))
--       = Const $ "leaf[#" ++ s ++ "]:" ++ x
--     alg (HC (Compose (s, BlobNode xs)))
--       = Const $ "blobNode[#" ++ s ++ "]: [" ++ intercalate ", " (fmap getConst xs) ++ "]"
    -- alg (FileNode n x :&: s)
    --   = Const $ "file[#" ++ s ++ "](" ++ n ++ "): " ++ getConst x
    -- alg (DirNode n xs :&: s)
    --   = Const $ "dir[#" ++ s ++ "](" ++ n ++ "): [" ++ intercalate ", " (fmap getConst xs) ++ "]"




data HashPointer p = HashPointer Int
type HashIndirect p = Const (HashPointer p)

type LazyHashTagged m p = (,) (HashPointer p) :+ m

-- type StoreF m
--   = forall i
--   . HashPointer
--  -> m $ DirTree

-- haha, whoops - turns out this nat tfn needs to know underlying type.. ah, yes! typed pointers..
-- note: will end up using coproduct here, maybe?


-- NOTE: START READING HERE
-- NOTE: I fundamentally can't do this with :-> because of the forall i. bit, it needs to have constraint on i being == p.. right?
-- fetch :: Read p => Monad m => HashIndirect p :-> LazyHashTagged m p
-- fetch (Const p) = C (p, pure $ read "lmao no")

lazyDeref'
  :: forall i m p
   . Monad m
  => HashIndirect p :-> LazyHashTagged m p
  -> C.Term ((:+) (HashIndirect     p) :+: DirTree) i
  -> C.Term ((:+) (LazyHashTagged m p) :++ DirTree) i
lazyDeref' = myFunction
  -- where
  --   f (C (p, Nothing)) = C (p, fetch p)
  --   f (C (p, Just x))  = C (p, pure x)

myFunction
  :: forall i f f' g
   . Functor f
  -- => Applicative f
  => C.HFunctor g
  => f :-> f'
  -> C.Term ((:+) f  :+: g) i
  -> C.Term ((:+) f' :++ g) i
myFunction nat
  = undefined
  -- = C.Term . HC . C
  -- . C.caseH nat pure . fmap (C.hfmap (myFunction nat))
  -- . getCompose . getHCompose . C.unTerm

-- myFunction'
--   :: forall i f f' g
--    . Functor f
--   => C.HFunctor g
--   => (((:+) f :++ g) -> ((:+) f' :++ g))
--   -> C.Term ((:+) f  :++ g) i
--   -> C.Term ((:+) f' :++ g) i
-- myFunction' nat
--   = C.Term . HC . C
--   . nat . fmap (C.hfmap (myFunction nat))
--   . getCompose . getHCompose . C.unTerm
